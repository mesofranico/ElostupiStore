import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import 'payment_controller.dart';

class MemberController extends GetxController {
  final RxList<Member> members = <Member>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Member?> selectedMember = Rx<Member?>(null);

  @override
  void onInit() {
    super.onInit();
    loadMembers();
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
    } finally {
      isLoading.value = false;
    }
  }

  // Carregar membros em atraso
  Future<void> loadOverdueMembers() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final List<Member> overdueMembers = await MemberService.getOverdueMembers();
      members.assignAll(overdueMembers);
    } catch (e) {
      errorMessage.value = e.toString();
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
      final List<Member> activeMembers = allMembers.where((member) => member.isActive).toList();
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
      
      final List<Member> filteredMembers = await MemberService.getMembersByPaymentStatus(status);
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
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
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
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
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
      
      // Recarregar também os pagamentos para atualizar a lista
      try {
        final PaymentController paymentController = Get.find<PaymentController>();
        await paymentController.loadPayments();
      } catch (e) {
        // Se não conseguir recarregar pagamentos, não é crítico
        if (kDebugMode) {
          print('Aviso: Não foi possível recarregar pagamentos após exclusão do membro: $e');
        }
      }
      
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
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
    return members.where((member) => 
      member.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Obter estatísticas
  Map<String, int> getStatistics() {
    final total = members.length;
    final active = members.where((m) => m.isActive).length;
    final overdue = members.where((m) => 
      m.paymentStatus == 'overdue' || 
      (m.nextPaymentDate != null && m.nextPaymentDate!.isBefore(DateTime.now()))
    ).length;
    final paid = members.where((m) => m.paymentStatus == 'paid').length;

    return {
      'total': total,
      'active': active,
      'overdue': overdue,
      'paid': paid,
    };
  }

  // Calcular próximo pagamento
  DateTime calculateNextPayment(DateTime lastPayment, String membershipType) {
    switch (membershipType.toLowerCase()) {
      case 'mensal':
        return DateTime(lastPayment.year, lastPayment.month + 1, lastPayment.day);
      case 'trimestral':
        return DateTime(lastPayment.year, lastPayment.month + 3, lastPayment.day);
      case 'semestral':
        return DateTime(lastPayment.year, lastPayment.month + 6, lastPayment.day);
      case 'anual':
        return DateTime(lastPayment.year + 1, lastPayment.month, lastPayment.day);
      default:
        return DateTime(lastPayment.year, lastPayment.month + 1, lastPayment.day);
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
      return {
        'error': e.toString(),
        'deletionComplete': false
      };
    }
  }
} 