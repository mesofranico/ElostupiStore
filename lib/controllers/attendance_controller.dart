import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/attendance_record.dart';
import '../models/consulente.dart';
import '../models/consulente_session.dart';
import '../services/attendance_service.dart';
import '../services/finance_service.dart';
import '../services/settings_service.dart';
import '../models/financial_record.dart';
import '../core/utils/ui_utils.dart';
import 'consulente_controller.dart';

class AttendanceController extends GetxController {
  final RxList<AttendanceRecord> attendanceRecords = <AttendanceRecord>[].obs;
  final RxList<Consulente> consulentesWithoutAttendance = <Consulente>[].obs;
  final RxList<Consulente> allConsulentes = <Consulente>[].obs;
  final RxList<ConsulenteSession> sessionsWithAcompanhantes =
      <ConsulenteSession>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxMap<String, int> attendanceStats = <String, int>{}.obs;

  Future<void> loadAttendanceForDate(DateTime date) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      debugPrint('=== DEBUG LOAD ATTENDANCE ===');
      debugPrint(
        'Carregando dados para: ${date.toIso8601String().split('T')[0]}',
      );

      // Limpar dados antigos antes de carregar novos
      attendanceRecords.clear();
      consulentesWithoutAttendance.clear();
      allConsulentes.clear();
      sessionsWithAcompanhantes.clear();
      attendanceStats.clear();

      selectedDate.value = date;

      // Carregar presenças do dia
      final records = await AttendanceService.getAttendanceByDate(date);
      attendanceRecords.value = records;
      debugPrint('Registos de presença carregados: ${records.length}');

      // Carregar sessões com acompanhantes do dia
      final sessions =
          await AttendanceService.getSessionsWithAcompanhantesByDate(date);
      sessionsWithAcompanhantes.value = sessions;
      debugPrint('Sessões com acompanhantes carregadas: ${sessions.length}');
      for (final session in sessions) {
        debugPrint(
          'Sessão ${session.id}: Consulente ${session.consulenteId}, Acompanhantes: ${session.acompanhantesIds}',
        );
      }

      // Carregar estatísticas
      final stats = await AttendanceService.getAttendanceStats(date);
      attendanceStats.value = stats;

      // Carregar todos os consulentes
      final allConsulentesList = await AttendanceService.getAllConsulentes();
      allConsulentes.value = allConsulentesList;
      debugPrint(
        'Todos os consulentes carregados: ${allConsulentesList.length}',
      );

      // Carregar consulentes sem presença registada
      final consulentes =
          await AttendanceService.getConsulentesWithoutAttendance(date);
      consulentesWithoutAttendance.value = consulentes;

      debugPrint('=== FIM DEBUG LOAD ATTENDANCE ===');
    } catch (e) {
      errorMessage.value = 'Erro ao carregar presenças: $e';
      debugPrint('Erro ao carregar presenças: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _recomputeStatsFromRecords() {
    int presentes = 0;
    int faltas = 0;
    int pendentes = 0;
    for (final r in attendanceRecords) {
      if (r.status == 'present') {
        presentes++;
      } else if (r.status == 'absent') {
        faltas++;
      } else {
        pendentes++;
      }
    }
    attendanceStats.value = {
      'presentes': presentes,
      'faltas': faltas,
      'pendentes': pendentes,
      'total_records': attendanceRecords.length,
    };
  }

  void markAttendance(int consulenteId, String status, {String? notes}) {
    errorMessage.value = '';
    final previousRecords = List<AttendanceRecord>.from(attendanceRecords);
    final previousStats = Map<String, int>.from(attendanceStats);

    final newList = List<AttendanceRecord>.from(attendanceRecords);
    final existingIndex = newList.indexWhere(
      (r) => r.consulenteId == consulenteId,
    );
    if (existingIndex >= 0) {
      newList[existingIndex] = newList[existingIndex].copyWith(
        status: status,
        notes: notes,
      );
    } else {
      newList.add(
        AttendanceRecord(
          consulenteId: consulenteId,
          attendanceDate: selectedDate.value,
          status: status,
          notes: notes,
        ),
      );
    }
    attendanceRecords.assignAll(newList);
    _recomputeStatsFromRecords();

    final record = AttendanceRecord(
      consulenteId: consulenteId,
      attendanceDate: selectedDate.value,
      status: status,
      notes: notes,
    );
    AttendanceService.createOrUpdateAttendance(record).then((_) {}).catchError((
      e,
    ) {
      debugPrint('Erro ao marcar presença: $e');
      attendanceRecords.assignAll(previousRecords);
      attendanceStats.assignAll(previousStats);
      UiUtils.showError(
        'Não foi possível atualizar a presença. Tente novamente.',
      );
    });
  }

  Future<void> markAttendanceWithPayment(
    int consulenteId,
    String status,
    int numberOfPayments,
  ) async {
    // 1. Marca a presença normalmente
    markAttendance(consulenteId, status);

    // 2. Regista o pagamento se for presente e tiver pagamentos > 0
    if (status == 'present' && numberOfPayments > 0) {
      try {
        final feeStr =
            await SettingsService.getSetting('attendance_fee') ?? '3.50';
        final fee = double.tryParse(feeStr) ?? 3.50;
        final totalAmount = fee * numberOfPayments;

        final consulente = allConsulentes.firstWhereOrNull(
          (c) => c.id == consulenteId,
        );
        final nome = consulente?.name ?? 'Consulente Desconhecido';

        await FinanceService.createRecord(
          FinancialRecord(
            type: 'income',
            category: 'Sessão',
            amount: totalAmount,
            description:
                'Pagamento Sessão - $nome ($numberOfPayments pessoa(s))',
            recordDate: selectedDate.value,
          ),
        );
        UiUtils.showSuccess(
          'Pagamento registado: ${totalAmount.toStringAsFixed(2)}€',
        );
      } catch (e) {
        debugPrint('Erro ao registar pagamento na presença: $e');
        UiUtils.showError(
          'Presença marcada, mas ocorreu um erro no registo financeiro.',
        );
      }
    }
  }

  Future<bool> updateAttendanceStatus(
    int recordId,
    String newStatus, {
    String? notes,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final record = attendanceRecords.firstWhere((r) => r.id == recordId);
      final updatedRecord = record.copyWith(status: newStatus, notes: notes);

      await AttendanceService.updateAttendance(recordId, updatedRecord);

      // Recarregar todos os dados da base de dados
      await loadAttendanceForDate(selectedDate.value);

      return true;
    } catch (e) {
      errorMessage.value = 'Erro ao atualizar presença: $e';
      debugPrint('Erro ao atualizar presença: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteAttendance(int recordId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Buscar o registo de presença para obter informações
      final record = attendanceRecords.firstWhere((r) => r.id == recordId);

      debugPrint('=== DEBUG DELETE ATTENDANCE ===');
      debugPrint('Eliminando marcação ID: $recordId');
      debugPrint('Consulente ID: ${record.consulenteId}');
      debugPrint('Data: ${record.attendanceDate}');

      // Eliminar a marcação de presença e sessões correspondentes (API faz tudo)
      await AttendanceService.deleteAttendance(recordId);

      debugPrint('Marcação e sessões eliminadas com sucesso via API');

      // Notificar o ConsulentesController para atualizar os dados
      try {
        final consulentesController = Get.find<ConsulentesController>();
        // Recarregar consulentes e estatísticas
        await consulentesController.loadConsulentes();
        // Forçar atualização das estatísticas
        await consulentesController.loadDetailedStatistics();
        debugPrint('ConsulentesController atualizado com sucesso');
      } catch (e) {
        debugPrint('Erro ao notificar ConsulentesController: $e');
      }

      // Recarregar todos os dados da base de dados
      await loadAttendanceForDate(selectedDate.value);

      debugPrint('=== FIM DEBUG DELETE ATTENDANCE ===');

      return true;
    } catch (e) {
      errorMessage.value = 'Erro ao deletar presença: $e';
      debugPrint('Erro ao deletar presença: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createBulkAttendance(List<int> consulenteIds) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await AttendanceService.createBulkAttendance(
        selectedDate.value,
        consulenteIds,
      );

      // Recarregar todos os dados da base de dados
      await loadAttendanceForDate(selectedDate.value);
    } catch (e) {
      errorMessage.value = 'Erro ao criar presenças em massa: $e';
      debugPrint('Erro ao criar presenças em massa: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changeDate(DateTime newDate) {
    loadAttendanceForDate(newDate);
  }

  void goToPreviousDay() {
    final previousDay = selectedDate.value.subtract(const Duration(days: 1));
    changeDate(previousDay);
  }

  void goToNextDay() {
    final nextDay = selectedDate.value.add(const Duration(days: 1));
    changeDate(nextDay);
  }

  void goToToday() {
    changeDate(DateTime.now());
  }

  List<AttendanceRecord> getPresentRecords() {
    return attendanceRecords.where((r) => r.isPresent).toList();
  }

  List<AttendanceRecord> getAbsentRecords() {
    return attendanceRecords.where((r) => r.isAbsent).toList();
  }

  List<AttendanceRecord> getPendingRecords() {
    return attendanceRecords.where((r) => r.isPending).toList();
  }

  AttendanceRecord? getRecordForConsulente(int consulenteId) {
    try {
      return attendanceRecords.firstWhere(
        (r) => r.consulenteId == consulenteId,
      );
    } catch (e) {
      return null;
    }
  }

  String getStatusForConsulente(int consulenteId) {
    final record = getRecordForConsulente(consulenteId);
    return record?.status ?? 'pending';
  }

  bool hasAttendanceForConsulente(int consulenteId) {
    return getRecordForConsulente(consulenteId) != null;
  }

  void clearError() {
    errorMessage.value = '';
  }

  Future<void> refreshData() async {
    attendanceRecords.clear();
    consulentesWithoutAttendance.clear();
    allConsulentes.clear();
    sessionsWithAcompanhantes.clear();
    attendanceStats.clear();
    errorMessage.value = '';

    try {
      final storage = GetStorage();
      await storage.remove('attendance_cache');
      await storage.remove('cached_attendance');
    } catch (_) {}

    await loadAttendanceForDate(selectedDate.value);
  }
}
