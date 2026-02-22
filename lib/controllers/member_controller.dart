import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import '../core/utils/ui_utils.dart';
import 'payment_controller.dart';

class MemberController extends GetxController {
  final RxList<Member> members = <Member>[].obs;
  final RxList<Member> filteredMembers = <Member>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Member?> selectedMember = Rx<Member?>(null);

  // Filtros de data para relatórios
  final Rx<DateTime?> filterStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> filterEndDate = Rx<DateTime?>(null);
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadMembers();

    // Debounce search to improve performance
    debounce(searchQuery, (String query) {
      filteredMembers.assignAll(filterMembersByName(query));
    }, time: const Duration(milliseconds: 400));

    // Also update filtered list when main list changes
    ever(members, (List<Member> allMembers) {
      filteredMembers.assignAll(filterMembersByName(searchQuery.value));
    });
  }

  // Carregar todos os membros
  Future<void> loadMembers() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final List<Member> loadedMembers = await MemberService.getAllMembers();
      members.assignAll(loadedMembers);
    } catch (e) {
      errorMessage.value = e.toString();
      UiUtils.showError('Não foi possível carregar os membros: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Carregar membros em atraso
  Future<void> loadOverdueMembers() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final List<Member> overdueMembers =
          await MemberService.getOverdueMembers();
      members.assignAll(overdueMembers);
    } catch (e) {
      errorMessage.value = e.toString();
      UiUtils.showError('Erro ao carregar membros em atraso: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Carregar apenas membros ativos
  Future<void> loadActiveMembers() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final List<Member> allMembers = await MemberService.getAllMembers();
      final List<Member> activeMembers = allMembers
          .where((member) => member.isActive)
          .toList();
      members.assignAll(activeMembers);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Carregar membros por status de pagamento
  Future<void> loadMembersByPaymentStatus(String status) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final List<Member> filteredMembers =
          await MemberService.getMembersByPaymentStatus(status);
      members.assignAll(filteredMembers);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Criar novo membro
  Future<bool> createMember(Member member) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final Member createdMember = await MemberService.createMember(member);
      members.add(createdMember);
      UiUtils.showSuccess('Membro criado com sucesso!');
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      UiUtils.showError('Erro ao criar membro: ${errorMessage.value}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Método para limpar cache e recarregar dados
  Future<void> refreshData() async {
    members.clear();
    errorMessage.value = '';

    // Verificar se há GetStorage sendo usado
    try {
      final storage = GetStorage();
      await storage.remove('members_cache');
      await storage.remove('cached_members');
    } catch (e) {
      // Ignorar erros de storage
    }

    await loadMembers();
  }

  // Atualizar membro
  Future<bool> updateMember(Member member) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final Member updatedMember = await MemberService.updateMember(member);
      final int index = members.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        members[index] = updatedMember;
      }
      UiUtils.showSuccess('Membro atualizado com sucesso!');
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      UiUtils.showError('Erro ao atualizar membro: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Deletar membro
  Future<bool> deleteMember(int id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await MemberService.deleteMember(id);
      members.removeWhere((member) => member.id == id);
      UiUtils.showSuccess('Membro excluído com sucesso!');

      // Recarregar também os pagamentos para atualizar a lista
      try {
        final PaymentController paymentController =
            Get.find<PaymentController>();
        await paymentController.loadPayments();
      } catch (e) {
        // Se não conseguir recarregar pagamentos, não é crítico
        if (kDebugMode) {
          print(
            'Aviso: Não foi possível recarregar pagamentos após exclusão do membro: $e',
          );
        }
      }

      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      if (kDebugMode) {
        print('Erro ao deletar membro: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Selecionar membro
  void selectMember(Member member) {
    selectedMember.value = member;
  }

  // Limpar seleção
  void clearSelection() {
    selectedMember.value = null;
  }

  // Filtrar membros por nome
  List<Member> filterMembersByName(String query) {
    if (query.isEmpty) return members;
    return members
        .where(
          (member) => member.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // Obter estatísticas
  Map<String, int> getStatistics() {
    final total = members.length;
    final active = members.where((m) => m.isActive).length;
    final overdue = members
        .where(
          (m) =>
              m.paymentStatus == 'overdue' ||
              (m.nextPaymentDate != null &&
                  m.nextPaymentDate!.isBefore(DateTime.now())),
        )
        .length;
    final paid = members.where((m) => m.paymentStatus == 'paid').length;

    return {'total': total, 'active': active, 'overdue': overdue, 'paid': paid};
  }

  // Calcular próximo pagamento
  DateTime calculateNextPayment(DateTime lastPayment, String membershipType) {
    switch (membershipType.toLowerCase()) {
      case 'mensal':
        return DateTime(
          lastPayment.year,
          lastPayment.month + 1,
          lastPayment.day,
        );
      case 'trimestral':
        return DateTime(
          lastPayment.year,
          lastPayment.month + 3,
          lastPayment.day,
        );
      case 'semestral':
        return DateTime(
          lastPayment.year,
          lastPayment.month + 6,
          lastPayment.day,
        );
      case 'anual':
        return DateTime(
          lastPayment.year + 1,
          lastPayment.month,
          lastPayment.day,
        );
      default:
        return DateTime(
          lastPayment.year,
          lastPayment.month + 1,
          lastPayment.day,
        );
    }
  }

  // Verificar se membro está em atraso
  bool isMemberOverdue(Member member) {
    if (member.nextPaymentDate == null) return false;
    return member.nextPaymentDate!.isBefore(DateTime.now());
  }

  // Obter dias em atraso
  int getDaysOverdue(Member member) {
    if (member.nextPaymentDate == null) return 0;
    final now = DateTime.now();
    final overdue = now.difference(member.nextPaymentDate!).inDays;
    return overdue > 0 ? overdue : 0;
  }

  // Verificar se a exclusão de um membro foi completa
  Future<Map<String, dynamic>> verifyMemberDeletion(int memberId) async {
    try {
      return await MemberService.verifyDeletion(memberId);
    } catch (e) {
      errorMessage.value = e.toString();
      return {'error': e.toString(), 'deletionComplete': false};
    }
  }

  // Aplicar filtro de data
  void applyDateFilter(DateTime startDate, DateTime endDate) {
    filterStartDate.value = startDate;
    filterEndDate.value = endDate;
  }

  // Limpar filtro de data
  void clearDateFilter() {
    filterStartDate.value = null;
    filterEndDate.value = null;
  }

  // Obter membros filtrados por data (para relatórios)
  List<Member> getFilteredMembers() {
    if (filterStartDate.value == null || filterEndDate.value == null) {
      return members;
    }

    return members.where((member) {
      // Filtrar por data de ingresso
      final joinDate = member.joinDate;
      final startDate = filterStartDate.value!;
      final endDate = filterEndDate.value!;

      return joinDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          joinDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
}
