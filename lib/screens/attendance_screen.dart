import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/attendance_controller.dart';
import '../models/attendance_record.dart';
import '../models/consulente.dart';
import '../services/attendance_service.dart';
import '../services/consulente_service.dart';
import '../widgets/standard_appbar.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AttendanceController controller = Get.find<AttendanceController>();

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Marcação de Presenças',
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () => controller.loadAttendanceForDate(controller.selectedDate.value),
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar dados',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadAttendanceForDate(controller.selectedDate.value),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        // Verificar se é a primeira vez que a tela é carregada
        if (controller.attendanceRecords.isEmpty && 
            controller.attendanceStats.isEmpty &&
            !controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecione uma data para ver as presenças',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use os botões de navegação ou toque na data',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => controller.loadAttendanceForDate(controller.selectedDate.value),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Carregar Dados'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildDateSelector(controller),
            _buildStatsCard(controller),
            Expanded(
              child: _buildAttendanceList(controller),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDateSelector(AttendanceController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[100]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: controller.goToPreviousDay,
            icon: const Icon(Icons.chevron_left),
          ),
          GestureDetector(
            onTap: () => _selectDate(controller),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                DateFormat('dd/MM/yyyy').format(controller.selectedDate.value),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: controller.goToToday,
                icon: const Icon(Icons.today),
                tooltip: 'Hoje',
              ),
              IconButton(
                onPressed: controller.goToNextDay,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(AttendanceController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Presentes',
            controller.attendanceStats['presentes'] ?? 0,
            Colors.green,
            Icons.check_circle,
          ),
          _buildStatItem(
            'Faltas',
            controller.attendanceStats['faltas'] ?? 0,
            Colors.red,
            Icons.cancel,
          ),
          _buildStatItem(
            'Pendentes',
            controller.attendanceStats['pendentes'] ?? 0,
            Colors.orange,
            Icons.schedule,
          ),
          _buildStatItem(
            'Total',
            controller.attendanceStats['total_records'] ?? 0,
            Colors.blue,
            Icons.people,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList(AttendanceController controller) {
    final allConsulentes = <Consulente>[];
    
    // Criar conjunto de IDs de acompanhantes para filtrar
    final acompanhantesIds = <int>{};
    for (final session in controller.sessionsWithAcompanhantes) {
      if (session.acompanhantesIds != null) {
        acompanhantesIds.addAll(session.acompanhantesIds!);
      }
    }
    
    // Adicionar todos os consulentes com presença registada
    for (final record in controller.attendanceRecords) {
      allConsulentes.add(Consulente(
        id: record.consulenteId,
        name: record.consulenteName ?? 'Nome não disponível',
        phone: record.consulentePhone ?? '',
        email: record.consulenteEmail,
      ));
    }
    
    // Filtrar apenas consulentes principais (não acompanhantes) para exibição
    final consulentesPrincipais = allConsulentes.where((consulente) => 
      !acompanhantesIds.contains(consulente.id)
    ).toList();
    
    debugPrint('=== DEBUG LISTA PRINCIPAL ===');
    debugPrint('Total de consulentes com presença: ${allConsulentes.length}');
    debugPrint('IDs de acompanhantes: $acompanhantesIds');
    debugPrint('Consulentes principais: ${consulentesPrincipais.length}');
    debugPrint('=== FIM DEBUG LISTA PRINCIPAL ===');

    if (consulentesPrincipais.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma presença registada para esta data',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'As presenças aparecem automaticamente quando são criadas sessões',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/consulentes'),
              icon: const Icon(Icons.people),
              label: const Text('Gestão de Consulentes'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: consulentesPrincipais.length,
      itemBuilder: (context, index) {
        final consulente = consulentesPrincipais[index];
        final attendanceRecord = controller.getRecordForConsulente(consulente.id!);
        final status = controller.getStatusForConsulente(consulente.id!);

        return _buildConsulenteCard(consulente, status, attendanceRecord, controller);
      },
    );
  }

  Widget _buildConsulenteCard(
    Consulente consulente,
    String status,
    AttendanceRecord? record,
    AttendanceController controller,
  ) {
    Color statusColor;
    IconData statusIcon;
    bool hasCompanions = false;

    // Verificar se este consulente tem sessões com acompanhantes
    for (final session in controller.sessionsWithAcompanhantes) {
      if (session.consulenteId == consulente.id && session.acompanhantesIds != null && session.acompanhantesIds!.isNotEmpty) {
        hasCompanions = true;
        debugPrint('Consulente ${consulente.id} tem acompanhantes: ${session.acompanhantesIds}');
        break;
      }
    }
    
    debugPrint('Consulente ${consulente.id} (${consulente.name}) - hasCompanions: $hasCompanions');

    switch (status) {
      case 'present':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'absent':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showNotesDialog(consulente, record, controller),
            onDoubleTap: record != null ? () => _showDeleteAttendanceDialog(controller, consulente.id!, record.id!) : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.1),
                child: Stack(
                  children: [
                    Icon(statusIcon, color: statusColor),
                    if (hasCompanions)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: const Icon(
                            Icons.group,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              title: Text(
                consulente.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(consulente.phone),
                  if (record != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Duplo toque para eliminar marcação',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusButton(
                    'Presente',
                    'present',
                    status,
                    Colors.green,
                    Icons.check,
                    controller,
                    consulente.id!,
                  ),
                  const SizedBox(width: 4),
                  _buildStatusButton(
                    'Faltou',
                    'absent',
                    status,
                    Colors.red,
                    Icons.close,
                    controller,
                    consulente.id!,
                  ),
                ],
              ),
            ),
          ),
          // Seção de acompanhantes usando FutureBuilder
          if (hasCompanions)
            FutureBuilder<List<Consulente>>(
              future: _getAcompanhantesForConsulente(consulente.id!, controller),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Carregando acompanhantes...',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  debugPrint('Erro ao carregar acompanhantes: ${snapshot.error}');
                  return const SizedBox.shrink();
                }
                
                final acompanhantes = snapshot.data ?? [];
                
                if (acompanhantes.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Acompanhantes:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: acompanhantes.map((acompanhante) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              acompanhante.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<List<Consulente>> _getAcompanhantesForConsulente(int consulenteId, AttendanceController controller) async {
    final List<Consulente> acompanhantes = [];
    
    debugPrint('=== DEBUG ACOMPANHANTES (API) ===');
    debugPrint('Consulente ID: $consulenteId');
    
    try {
      // Buscar sessões diretamente da API para garantir dados atualizados
      final sessions = await AttendanceService.getSessionsWithAcompanhantesByDate(controller.selectedDate.value);
      debugPrint('Sessões carregadas da API: ${sessions.length}');
      
      // Buscar sessões onde este consulente é o principal
      for (final session in sessions) {
        debugPrint('Sessão ID: ${session.id}, Consulente ID: ${session.consulenteId}, Acompanhantes: ${session.acompanhantesIds}');
        
        if (session.consulenteId == consulenteId && session.acompanhantesIds != null) {
          debugPrint('Encontrada sessão para consulente $consulenteId com ${session.acompanhantesIds!.length} acompanhantes');
          
          // Buscar informações dos acompanhantes diretamente da API
          for (final acompanhanteId in session.acompanhantesIds!) {
            debugPrint('Processando acompanhante ID: $acompanhanteId');
            
            try {
              // Buscar informações do acompanhante diretamente da API
              final acompanhante = await ConsulentesService.getConsulenteById(acompanhanteId);
              debugPrint('Acompanhante encontrado na API: ${acompanhante.name}');
              acompanhantes.add(acompanhante);
            } catch (e) {
              debugPrint('Erro ao buscar acompanhante $acompanhanteId da API: $e');
              
              // Fallback: buscar nos registos de presença se disponível
              try {
                final attendanceRecord = controller.attendanceRecords.firstWhere(
                  (r) => r.consulenteId == acompanhanteId,
                );
                debugPrint('Acompanhante encontrado nos registos de presença: ${attendanceRecord.consulenteName}');
                
                final acompanhante = Consulente(
                  id: acompanhanteId,
                  name: attendanceRecord.consulenteName ?? 'Consulente $acompanhanteId',
                  phone: attendanceRecord.consulentePhone ?? '',
                  email: attendanceRecord.consulenteEmail,
                );
                acompanhantes.add(acompanhante);
              } catch (e2) {
                debugPrint('Acompanhante não encontrado em nenhum lugar, criando temporário');
                
                // Último recurso: criar um consulente temporário
                final acompanhante = Consulente(
                  id: acompanhanteId,
                  name: 'Consulente $acompanhanteId',
                  phone: '',
                );
                acompanhantes.add(acompanhante);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar sessões da API: $e');
    }
    
    debugPrint('Total de acompanhantes encontrados: ${acompanhantes.length}');
    debugPrint('=== FIM DEBUG ACOMPANHANTES (API) ===');
    
    return acompanhantes;
  }

  Widget _buildStatusButton(
    String label,
    String statusValue,
    String currentStatus,
    Color color,
    IconData icon,
    AttendanceController controller,
    int consulenteId,
  ) {
    final isSelected = currentStatus == statusValue;
    
    return GestureDetector(
      onTap: () => controller.markAttendance(consulenteId, statusValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(AttendanceController controller) async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != controller.selectedDate.value) {
      controller.changeDate(picked);
    }
  }

  void _showNotesDialog(
    Consulente consulente,
    AttendanceRecord? record,
    AttendanceController controller,
  ) {
    final notesController = TextEditingController(text: record?.notes ?? '');
    final isAutomatic = record?.notes != null && record!.notes!.contains('Presença automática');
    
    Get.dialog(
      AlertDialog(
        title: Text('Notas - ${consulente.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAutomatic) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Presença automática criada por sessão (Pendente)',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Adicionar notas sobre a presença...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final currentStatus = controller.getStatusForConsulente(consulente.id!);
              controller.markAttendance(
                consulente.id!,
                currentStatus,
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              );
              Get.back();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAttendanceDialog(AttendanceController controller, int consulenteId, int recordId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Marcação'),
        content: const Text('Tem a certeza que deseja eliminar esta marcação de presença?\n\n⚠️ ATENÇÃO: A sessão correspondente também será removida do histórico do consulente.\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await controller.deleteAttendance(recordId);
              if (success) {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  const SnackBar(
                    content: Text('Marcação e sessão eliminadas com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  SnackBar(
                    content: Text(controller.errorMessage.value),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
