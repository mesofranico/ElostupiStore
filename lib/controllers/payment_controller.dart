import 'package:get/get.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import '../core/utils/ui_utils.dart';
import 'member_controller.dart';

class PaymentController extends GetxController {
  final RxList<Payment> payments = <Payment>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Payment?> selectedPayment = Rx<Payment?>(null);
  final Rx<DateTime> selectedStartDate = DateTime.now()
      .subtract(const Duration(days: 30))
      .obs;
  final Rx<DateTime> selectedEndDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadPayments();
  }

  // Carregar todos os pagamentos
  Future<void> loadPayments() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final List<Payment> loadedPayments =
          await PaymentService.getAllPayments();
      payments.assignAll(loadedPayments);
    } catch (e) {
      errorMessage.value = e.toString();
      UiUtils.showError('Erro ao carregar pagamentos: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Carregar pagamentos por membro
  Future<void> loadPaymentsByMember(int memberId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final List<Payment> memberPayments =
          await PaymentService.getPaymentsByMember(memberId);
      payments.assignAll(memberPayments);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Carregar pagamentos por período
  Future<void> loadPaymentsByPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final List<Payment> periodPayments =
          await PaymentService.getPaymentsByPeriod(startDate, endDate);
      payments.assignAll(periodPayments);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Carregar pagamentos por status
  Future<void> loadPaymentsByStatus(String status) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final List<Payment> statusPayments =
          await PaymentService.getPaymentsByStatus(status);
      payments.assignAll(statusPayments);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Criar novo pagamento
  Future<bool> createPayment(
    Payment payment, {
    bool showSnackbar = true,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) isLoading.value = true;
      errorMessage.value = '';

      final Payment createdPayment = await PaymentService.createPayment(
        payment,
      );
      payments.add(createdPayment);
      if (showSnackbar) {
        UiUtils.showSuccess('Pagamento registado com sucesso!');
      }
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      if (showSnackbar) {
        UiUtils.showError('Erro ao registar pagamento: $e');
      }
      return false;
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  // Atualizar pagamento
  Future<bool> updatePayment(Payment payment) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final Payment updatedPayment = await PaymentService.updatePayment(
        payment,
      );
      final int index = payments.indexWhere((p) => p.id == payment.id);
      if (index != -1) {
        payments[index] = updatedPayment;
      }
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Deletar pagamento
  Future<bool> deletePayment(int id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await PaymentService.deletePayment(id);
      payments.removeWhere((payment) => payment.id == id);
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Selecionar pagamento
  void selectPayment(Payment payment) {
    selectedPayment.value = payment;
  }

  // Limpar seleção
  void clearSelection() {
    selectedPayment.value = null;
  }

  // Definir período de relatório
  void setReportPeriod(DateTime startDate, DateTime endDate) {
    selectedStartDate.value = startDate;
    selectedEndDate.value = endDate;
  }

  // Obter relatório de pagamentos
  Future<Map<String, dynamic>?> getPaymentReport() async {
    try {
      UiUtils.showLoadingOverlay(message: 'Gerando relatório...');
      isLoading.value = true;
      errorMessage.value = '';

      final report = await PaymentService.getPaymentReport(
        selectedStartDate.value,
        selectedEndDate.value,
      );
      return report;
    } catch (e) {
      errorMessage.value = e.toString();
      UiUtils.hideLoading(); // Close first
      UiUtils.showError('Erro ao gerar relatório: $e');
      return null;
    } finally {
      isLoading.value = false;
      UiUtils.hideLoading();
    }
  }

  // Filtrar pagamentos por período
  List<Payment> filterPaymentsByPeriod(DateTime startDate, DateTime endDate) {
    return payments
        .where(
          (payment) =>
              payment.paymentDate.isAfter(startDate) &&
              payment.paymentDate.isBefore(endDate),
        )
        .toList();
  }

  // Obter estatísticas de pagamentos
  Map<String, dynamic> getPaymentStatistics() {
    final total = payments.length;
    final totalAmount = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final completed = payments.where((p) => p.status == 'completed').length;
    final failed = payments.where((p) => p.status == 'failed').length;

    // Agrupar por mês
    final Map<String, double> byMonth = {};
    for (final payment in payments) {
      final monthKey =
          '${payment.paymentDate.year}-${payment.paymentDate.month.toString().padLeft(2, '0')}';
      byMonth[monthKey] = (byMonth[monthKey] ?? 0) + payment.amount;
    }

    return {
      'total': total,
      'totalAmount': totalAmount,
      'completed': completed,
      'failed': failed,
      'byMonth': byMonth,
    };
  }

  // Obter pagamentos do mês atual
  List<Payment> getCurrentMonthPayments() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return payments
        .where(
          (payment) =>
              payment.paymentDate.isAfter(startOfMonth) &&
              payment.paymentDate.isBefore(endOfMonth),
        )
        .toList();
  }

  // Obter pagamentos com falha
  List<Payment> getFailedPayments() {
    return payments.where((payment) => payment.status == 'failed').toList();
  }

  // Obter pagamentos filtrados por data (para relatórios)
  List<Payment> getFilteredPayments() {
    final memberController = Get.find<MemberController>();
    if (memberController.filterStartDate.value == null ||
        memberController.filterEndDate.value == null) {
      return payments;
    }

    final startDate = memberController.filterStartDate.value!;
    final endDate = memberController.filterEndDate.value!;

    return payments.where((payment) {
      final paymentDate = payment.paymentDate;
      return paymentDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          paymentDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
}
