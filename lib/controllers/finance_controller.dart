import 'package:get/get.dart';
import '../models/financial_record.dart';
import '../services/finance_service.dart';
import '../core/utils/ui_utils.dart';

class FinanceController extends GetxController {
  final RxList<FinancialRecord> records = <FinancialRecord>[].obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> consolidatedReport = <String, dynamic>{}.obs;

  // Filtros
  final Rx<DateTime> startDate = DateTime.now()
      .subtract(const Duration(days: 30))
      .obs;
  final Rx<DateTime> endDate = DateTime.now().obs;
  final RxString selectedPeriodType =
      'monthly'.obs; // 'daily', 'weekly', 'monthly'

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  Future<void> loadAllData() async {
    await Future.wait([loadRecords(), loadReport()]);
  }

  Future<void> loadRecords() async {
    try {
      isLoading.value = true;
      final result = await FinanceService.getRecords(
        start: startDate.value,
        end: endDate.value,
      );
      records.assignAll(result);
    } catch (e) {
      UiUtils.showError('Erro ao carregar registos financeiros: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadReport() async {
    try {
      final report = await FinanceService.getConsolidatedReport(
        startDate.value,
        endDate.value,
      );
      consolidatedReport.value = report;
    } catch (e) {
      // Ignorar erro silenciosamente em background ou usar log
    }
  }

  Future<bool> addRecord(FinancialRecord record) async {
    try {
      UiUtils.showLoadingOverlay(message: 'A guardar registo...');
      await FinanceService.createRecord(record);
      await loadAllData();
      UiUtils.hideLoading();
      UiUtils.showSuccess('Registo financeiro guardado!');
      return true;
    } catch (e) {
      UiUtils.hideLoading();
      UiUtils.showError('Erro ao guardar registo: $e');
      return false;
    } finally {
      // Garantir que fecha se carregar em cancelar ou outro fluxo
      UiUtils.hideLoading();
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      if (await UiUtils.showConfirm(
        'Eliminar registo?',
        'Esta ação não pode ser desfeita.',
      )) {
        UiUtils.showLoadingOverlay(message: 'A eliminar...');
        await FinanceService.deleteRecord(id);
        await loadAllData();
        UiUtils.hideLoading();
        UiUtils.showSuccess('Registo eliminado!');
      }
    } catch (e) {
      UiUtils.hideLoading();
      UiUtils.showError('Erro ao eliminar: $e');
    } finally {
      UiUtils.hideLoading();
    }
  }

  void setPeriod(String type) {
    selectedPeriodType.value = type;
    final now = DateTime.now();
    switch (type) {
      case 'daily':
        startDate.value = DateTime(now.year, now.month, now.day);
        endDate.value = now;
        break;
      case 'weekly':
        startDate.value = now.subtract(Duration(days: now.weekday - 1));
        endDate.value = now;
        break;
      case 'monthly':
        startDate.value = DateTime(now.year, now.month, 1);
        endDate.value = now;
        break;
    }
    loadAllData();
  }

  void setDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    selectedPeriodType.value = 'custom';
    loadAllData();
  }

  double get totalIncome =>
      consolidatedReport['income']?['total']?.toDouble() ?? 0.0;
  double get totalExpense =>
      consolidatedReport['expense']?['total']?.toDouble() ?? 0.0;
  double get balance => consolidatedReport['balance']?.toDouble() ?? 0.0;
}
