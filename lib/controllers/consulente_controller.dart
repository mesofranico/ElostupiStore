import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/consulente.dart';
import '../models/consulente_session.dart';
import '../services/consulente_service.dart';
import 'attendance_controller.dart';

class ConsulentesController extends GetxController {
  final RxList<Consulente> consulentes = <Consulente>[].obs;
  final RxList<ConsulenteSession> sessions = <ConsulenteSession>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<Consulente?> selectedConsulente = Rx<Consulente?>(null);
  final RxMap<int, int> sessionCounts = <int, int>{}.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadConsulentes();
  }

  // Carregar todos os consulentes
  Future<void> loadConsulentes() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final List<Consulente> loadedConsulentes = await ConsulentesService.getAllConsulentes();
      consulentes.assignAll(loadedConsulentes);
      
      // Carregar estatísticas detalhadas (inclui contagens de sessões)
      await loadDetailedStatistics();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Criar novo consulente
  Future<bool> createConsulente(Consulente consulente) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final Consulente createdConsulente = await ConsulentesService.createConsulente(consulente);
      consulentes.add(createdConsulente);
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Atualizar consulente
  Future<bool> updateConsulente(Consulente consulente) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final Consulente updatedConsulente = await ConsulentesService.updateConsulente(consulente);
      final int index = consulentes.indexWhere((c) => c.id == consulente.id);
      if (index != -1) {
        consulentes[index] = updatedConsulente;
      }
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Deletar consulente
  Future<bool> deleteConsulente(int id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await ConsulentesService.deleteConsulente(id);
      consulentes.removeWhere((consulente) => consulente.id == id);
      
      // Se o consulente deletado estava selecionado, limpar seleção
      if (selectedConsulente.value?.id == id) {
        selectedConsulente.value = null;
        sessions.clear();
      }
      
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      if (kDebugMode) {
        print('Erro ao deletar consulente: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Selecionar consulente
  void selectConsulente(Consulente consulente) {
    selectedConsulente.value = consulente;
    loadConsulenteSessions(consulente.id!);
  }

  // Limpar seleção
  void clearSelection() {
    selectedConsulente.value = null;
    sessions.clear();
  }

  // Carregar sessões de um consulente
  Future<void> loadConsulenteSessions(int consulenteId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final List<ConsulenteSession> loadedSessions = await ConsulentesService.getConsulenteSessions(consulenteId);
      sessions.assignAll(loadedSessions);
      
      // Guardar contagem de sessões para este consulente
      sessionCounts[consulenteId] = loadedSessions.length;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Criar nova sessão
  Future<bool> createSession(ConsulenteSession session) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final ConsulenteSession createdSession = await ConsulentesService.createSession(session);
      sessions.add(createdSession);
      
      // Atualizar contagem de sessões
      final currentCount = sessionCounts[session.consulenteId] ?? 0;
      sessionCounts[session.consulenteId] = currentCount + 1;
      
      // Ordenar sessões por data (mais recente primeiro)
      sessions.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
      
      // Notificar o AttendanceController para recarregar os dados
      try {
        final attendanceController = Get.find<AttendanceController>();
        attendanceController.loadAttendanceForDate(attendanceController.selectedDate.value);
      } catch (e) {
        // AttendanceController pode não estar inicializado ainda
        if (kDebugMode) {
          print('AttendanceController não encontrado: $e');
        }
      }
      
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Atualizar sessão
  Future<bool> updateSession(ConsulenteSession session) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final ConsulenteSession updatedSession = await ConsulentesService.updateSession(session);
      final int index = sessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        sessions[index] = updatedSession;
      }
      
      // Reordenar sessões
      sessions.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
      
      // Notificar o AttendanceController para recarregar os dados
      try {
        final attendanceController = Get.find<AttendanceController>();
        // Usar addPostFrameCallback para evitar setState durante build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          attendanceController.loadAttendanceForDate(attendanceController.selectedDate.value);
        });
      } catch (e) {
        if (kDebugMode) {
          print('AttendanceController não encontrado: $e');
        }
      }
      
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Deletar sessão
  Future<bool> deleteSession(int sessionId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await ConsulentesService.deleteSession(sessionId);
      
      // Encontrar a sessão para obter o consulenteId
      final sessionToDelete = sessions.firstWhere((s) => s.id == sessionId);
      sessions.removeWhere((session) => session.id == sessionId);
      
      // Atualizar contagem de sessões
      final currentCount = sessionCounts[sessionToDelete.consulenteId] ?? 0;
      sessionCounts[sessionToDelete.consulenteId] = (currentCount - 1).clamp(0, double.infinity).toInt();
      
      // Notificar o AttendanceController para recarregar os dados
      try {
        final attendanceController = Get.find<AttendanceController>();
        // Usar addPostFrameCallback para evitar setState durante build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          attendanceController.loadAttendanceForDate(attendanceController.selectedDate.value);
        });
      } catch (e) {
        if (kDebugMode) {
          print('AttendanceController não encontrado: $e');
        }
      }
      
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      if (kDebugMode) {
        print('Erro ao deletar sessão: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Filtrar consulentes por nome
  List<Consulente> filterConsulentesByName(String query) {
    if (query.isEmpty) return consulentes;
    return consulentes.where((consulente) => 
      consulente.name.toLowerCase().contains(query.toLowerCase()) ||
      consulente.phone.contains(query) ||
      (consulente.email?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }

  // Obter consulentes filtrados pela pesquisa atual
  List<Consulente> get filteredConsulentes {
    return filterConsulentesByName(searchQuery.value);
  }

  // Atualizar query de pesquisa
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  // Limpar pesquisa
  void clearSearch() {
    searchQuery.value = '';
  }

  // Obter estatísticas (sempre da API)
  Future<Map<String, int>> getStatistics() async {
    try {
      return await loadDetailedStatistics();
    } catch (e) {
      debugPrint('Erro ao carregar estatísticas: $e');
      // Fallback para estatísticas básicas
      return {
        'total': consulentes.length,
        'withSessions': 0,
        'recentSessions': 0,
      };
    }
  }

  // Obter sessões recentes (últimos 30 dias)
  List<ConsulenteSession> get recentSessions {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return sessions.where((s) => s.sessionDate.isAfter(thirtyDaysAgo)).toList();
  }

  // Obter próxima sessão agendada
  ConsulenteSession? get nextScheduledSession {
    final now = DateTime.now();
    final futureSessions = sessions.where((s) => s.sessionDate.isAfter(now)).toList();
    if (futureSessions.isEmpty) return null;
    
    futureSessions.sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
    return futureSessions.first;
  }

  // Método para limpar cache e recarregar dados
  Future<void> refreshData() async {
    consulentes.clear();
    sessions.clear();
    errorMessage.value = '';
    searchQuery.value = '';
    
    // Verificar se há GetStorage sendo usado
    try {
      final storage = GetStorage();
      await storage.remove('consulentes_cache');
      await storage.remove('cached_consulentes');
    } catch (e) {
      // Ignorar erros de storage
    }
    
    await loadConsulentes();
  }

  // Verificar se há sessões para um consulente (sempre da API)
  Future<bool> hasSessions(int consulenteId) async {
    try {
      final sessions = await ConsulentesService.getConsulenteSessions(consulenteId);
      return sessions.isNotEmpty;
    } catch (e) {
      debugPrint('Erro ao verificar sessões: $e');
      return false;
    }
  }

  // Obter número de sessões para um consulente (sempre da API)
  Future<int> getSessionCount(int consulenteId) async {
    try {
      final sessions = await ConsulentesService.getConsulenteSessions(consulenteId);
      return sessions.length;
    } catch (e) {
      debugPrint('Erro ao obter contagem de sessões: $e');
      return 0;
    }
  }

  // Obter última sessão de um consulente (sempre da API)
  Future<ConsulenteSession?> getLastSession(int consulenteId) async {
    try {
      final sessions = await ConsulentesService.getConsulenteSessions(consulenteId);
      if (sessions.isEmpty) return null;
      
      // Criar uma cópia da lista para ordenação sem modificar a lista original
      final sortedSessions = List<ConsulenteSession>.from(sessions);
      sortedSessions.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
      return sortedSessions.first;
    } catch (e) {
      debugPrint('Erro ao obter última sessão: $e');
      return null;
    }
  }

  // Carregar contagens de sessões para todos os consulentes
  Future<void> loadSessionCounts() async {
    try {
      for (final consulente in consulentes) {
        if (consulente.id != null) {
          final sessions = await ConsulentesService.getConsulenteSessions(consulente.id!);
          sessionCounts[consulente.id!] = sessions.length;
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar contagens de sessões: $e');
    }
  }

  // Carregar estatísticas detalhadas incluindo sessões recentes
  Future<Map<String, int>> loadDetailedStatistics() async {
    try {
      final total = consulentes.length;
      int withSessions = 0;
      int recentSessions = 0;
      
      for (final consulente in consulentes) {
        if (consulente.id != null) {
          final sessions = await ConsulentesService.getConsulenteSessions(consulente.id!);
          sessionCounts[consulente.id!] = sessions.length;
          
          if (sessions.isNotEmpty) {
            withSessions++;
            
            // Contar sessões recentes (últimos 30 dias)
            final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
            recentSessions += sessions.where((s) => s.sessionDate.isAfter(thirtyDaysAgo)).length;
          }
        }
      }
      
      return {
        'total': total,
        'withSessions': withSessions,
        'recentSessions': recentSessions,
      };
    } catch (e) {
      debugPrint('Erro ao carregar estatísticas detalhadas: $e');
      return getStatistics(); // Fallback para estatísticas básicas
    }
  }

}
