import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/attendance_controller.dart';
import '../models/attendance_record.dart';
import '../models/consulente.dart';
import '../services/attendance_service.dart';
import '../services/consulente_service.dart';
import '../widgets/standard_appbar.dart';
import '../core/utils/ui_utils.dart';
import '../widgets/loading_view.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final AttendanceController controller = Get.find<AttendanceController>();
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      controller.selectedDate.value = today;
      controller.loadAttendanceForDate(today);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AttendanceController controller = Get.find<AttendanceController>();

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Marcação de presenças',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: () =>
                controller.loadAttendanceForDate(controller.selectedDate.value),
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar dados',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingView();
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  controller.errorMessage.value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => controller.loadAttendanceForDate(
                    controller.selectedDate.value,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        if (controller.attendanceRecords.isEmpty &&
            controller.attendanceStats.isEmpty &&
            !controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 56,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  'Selecione uma data para ver as presenças',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use os botões de navegação ou toque na data',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => controller.loadAttendanceForDate(
                    controller.selectedDate.value,
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Carregar dados'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildDateSelector(context, controller),
            _buildStatsCard(context, controller),
            Expanded(child: _buildAttendanceList(context, controller)),
          ],
        );
      }),
    );
  }

  Widget _buildDateSelector(
    BuildContext context,
    AttendanceController controller,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: controller.goToPreviousDay,
            icon: Icon(Icons.chevron_left, color: theme.colorScheme.primary),
          ),
          GestureDetector(
            onTap: () => _selectDate(controller),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.6,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Text(
                DateFormat('dd/MM/yyyy').format(controller.selectedDate.value),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: controller.goToNextDay,
            icon: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    AttendanceController controller,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Presentes',
              controller.attendanceStats['presentes'] ?? 0,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              'Faltas',
              controller.attendanceStats['faltas'] ?? 0,
              theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              'Pendentes',
              controller.attendanceStats['pendentes'] ?? 0,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              context,
              'Total',
              controller.attendanceStats['total_records'] ?? 0,
              theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    int value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(
    BuildContext context,
    AttendanceController controller,
  ) {
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
      allConsulentes.add(
        Consulente(
          id: record.consulenteId,
          name: record.consulenteName ?? 'Nome não disponível',
          phone: record.consulentePhone ?? '',
          email: record.consulenteEmail,
        ),
      );
    }

    // Filtrar apenas consulentes principais (não acompanhantes) para exibição
    final consulentesPrincipais = allConsulentes
        .where((consulente) => !acompanhantesIds.contains(consulente.id))
        .toList();

    debugPrint('=== DEBUG LISTA PRINCIPAL ===');
    debugPrint('Total de consulentes com presença: ${allConsulentes.length}');
    debugPrint('IDs de acompanhantes: $acompanhantesIds');
    debugPrint('Consulentes principais: ${consulentesPrincipais.length}');
    debugPrint('=== FIM DEBUG LISTA PRINCIPAL ===');

    if (consulentesPrincipais.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma presença registada para esta data',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'As presenças aparecem automaticamente quando são criadas sessões',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Get.toNamed('/consulentes'),
              icon: const Icon(Icons.people, size: 18),
              label: const Text('Gestão de Consulentes'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: consulentesPrincipais.length,
      itemBuilder: (context, index) {
        final consulente = consulentesPrincipais[index];
        final attendanceRecord = controller.getRecordForConsulente(
          consulente.id!,
        );
        final status = controller.getStatusForConsulente(consulente.id!);

        return _buildConsulenteCard(
          context,
          consulente,
          status,
          attendanceRecord,
          controller,
        );
      },
    );
  }

  Widget _buildConsulenteCard(
    BuildContext context,
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
      if (session.consulenteId == consulente.id &&
          ((session.acompanhantesIds != null &&
                  session.acompanhantesIds!.isNotEmpty) ||
              session.extraAcompanhantes > 0)) {
        hasCompanions = true;
        debugPrint(
          'Consulente ${consulente.id} tem acompanhantes registados ou extras',
        );
        break;
      }
    }

    debugPrint(
      'Consulente ${consulente.id} (${consulente.name}) - hasCompanions: $hasCompanions',
    );

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

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showNotesDialog(consulente, record, controller),
              onDoubleTap: record != null
                  ? () => _showDeleteAttendanceDialog(
                      controller,
                      consulente.id!,
                      record.id!,
                    )
                  : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.15),
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
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.group,
                                  size: 8,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            consulente.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            consulente.phone,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (record != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Duplo toque para eliminar marcação',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildStatusSegmented(
                        status,
                        consulente.id!,
                        controller,
                        hasCompanions,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Seção de acompanhantes usando FutureBuilder
          if (hasCompanions)
            FutureBuilder<List<Consulente>>(
              future: _getAcompanhantesForConsulente(
                consulente.id!,
                controller,
              ),
              builder: (context, snapshot) {
                final theme = Theme.of(context);
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'A carregar acompanhantes...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  debugPrint(
                    'Erro ao carregar acompanhantes: ${snapshot.error}',
                  );
                  return const SizedBox.shrink();
                }
                final acompanhantes = snapshot.data ?? [];
                if (acompanhantes.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Acompanhantes:',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: acompanhantes.map((acompanhante) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              acompanhante.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
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

  Future<List<Consulente>> _getAcompanhantesForConsulente(
    int consulenteId,
    AttendanceController controller,
  ) async {
    final List<Consulente> acompanhantes = [];

    debugPrint('=== DEBUG ACOMPANHANTES (API) ===');
    debugPrint('Consulente ID: $consulenteId');

    try {
      // Buscar sessões diretamente da API para garantir dados atualizados
      final sessions =
          await AttendanceService.getSessionsWithAcompanhantesByDate(
            controller.selectedDate.value,
          );
      debugPrint('Sessões carregadas da API: ${sessions.length}');

      // Buscar sessões onde este consulente é o principal
      for (final session in sessions) {
        debugPrint(
          'Sessão ID: ${session.id}, Consulente ID: ${session.consulenteId}, Acompanhantes: ${session.acompanhantesIds}, Extras: ${session.extraAcompanhantes}',
        );

        if (session.consulenteId == consulenteId) {
          final bool hasRegistered =
              session.acompanhantesIds != null &&
              session.acompanhantesIds!.isNotEmpty;
          final bool hasExtra = session.extraAcompanhantes > 0;

          if (hasRegistered || hasExtra) {
            debugPrint(
              'Encontrada sessão para consulente $consulenteId com acompanhantes (Registados: $hasRegistered, Extras: $hasExtra)',
            );

            if (hasRegistered) {
              // Buscar informações dos acompanhantes diretamente da API
              for (final acompanhanteId in session.acompanhantesIds!) {
                debugPrint('Processando acompanhante ID: $acompanhanteId');

                try {
                  // Buscar informações do acompanhante diretamente da API
                  final acompanhante =
                      await ConsulentesService.getConsulenteById(
                        acompanhanteId,
                      );
                  debugPrint(
                    'Acompanhante encontrado na API: ${acompanhante.name}',
                  );
                  acompanhantes.add(acompanhante);
                } catch (e) {
                  debugPrint(
                    'Erro ao buscar acompanhante $acompanhanteId da API: $e',
                  );

                  // Fallback: buscar nos registos de presença se disponível
                  try {
                    final attendanceRecord = controller.attendanceRecords
                        .firstWhere((r) => r.consulenteId == acompanhanteId);
                    debugPrint(
                      'Acompanhante encontrado nos registos de presença: ${attendanceRecord.consulenteName}',
                    );

                    final acompanhante = Consulente(
                      id: acompanhanteId,
                      name:
                          attendanceRecord.consulenteName ??
                          'Consulente $acompanhanteId',
                      phone: attendanceRecord.consulentePhone ?? '',
                      email: attendanceRecord.consulenteEmail,
                    );
                    acompanhantes.add(acompanhante);
                  } catch (e2) {
                    debugPrint(
                      'Acompanhante não encontrado em nenhum lugar, criando temporário',
                    );

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

            if (hasExtra) {
              acompanhantes.add(
                Consulente(
                  id: -1, // ID negativo para não conflitar com reais
                  name: '${session.extraAcompanhantes} Acompanhante(s)',
                  phone: '',
                ),
              );
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

  Widget _buildStatusSegmented(
    String currentStatus,
    int consulenteId,
    AttendanceController controller,
    bool hasCompanions,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final surface = theme.colorScheme.surfaceContainerHighest;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final outline = theme.colorScheme.outlineVariant;
    const radius = 6.0;

    Widget segment(String value, String label, IconData icon) {
      final isSelected = currentStatus == value;
      final bgColor = isSelected ? primary : surface;
      final fgColor = isSelected ? onPrimary : onSurfaceVariant;
      final isFirst = value == 'pending';
      final isLast = value == 'absent';
      final borderRadius = BorderRadius.only(
        topLeft: Radius.circular(isFirst ? radius : 0),
        bottomLeft: Radius.circular(isFirst ? radius : 0),
        topRight: Radius.circular(isLast ? radius : 0),
        bottomRight: Radius.circular(isLast ? radius : 0),
      );

      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (value == 'present' && currentStatus != 'present') {
                _handlePresentAndPayment(
                  consulenteId,
                  controller,
                  hasCompanions,
                );
              } else {
                controller.markAttendance(consulenteId, value);
              }
            },
            borderRadius: borderRadius,
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: borderRadius,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: fgColor),
                  const SizedBox(width: 3),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: fgColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            segment('pending', 'Pendente', Icons.schedule),
            segment('present', 'Presente', Icons.check_circle_outline),
            segment('absent', 'Faltou', Icons.cancel_outlined),
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
    final theme = Get.context != null ? Theme.of(Get.context!) : null;
    final notesController = TextEditingController(text: record?.notes ?? '');
    final isAutomatic =
        record?.notes != null && record!.notes!.contains('Presença automática');
    Get.dialog(
      AlertDialog(
        title: Text('Notas - ${consulente.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAutomatic && theme != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Presença automática criada por sessão (Pendente)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
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
              decoration: InputDecoration(
                hintText: 'Adicionar notas sobre a presença...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: theme?.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final currentStatus = controller.getStatusForConsulente(
                consulente.id!,
              );
              controller.markAttendance(
                consulente.id!,
                currentStatus,
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );
              Get.back();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAttendanceDialog(
    AttendanceController controller,
    int consulenteId,
    int recordId,
  ) {
    UiUtils.showConfirmDialog(
      title: 'Eliminar marcação',
      message:
          'Tem a certeza que deseja eliminar esta marcação de presença?\n\n'
          '⚠️ ATENÇÃO: A sessão correspondente também será removida do histórico do consulente.\n\n'
          'Esta ação não pode ser desfeita.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline,
      color: Theme.of(Get.context!).colorScheme.error,
      onConfirm: () async {
        final success = await controller.deleteAttendance(recordId);
        if (success) {
          UiUtils.showSuccess('Marcação e sessão eliminadas com sucesso');
        } else {
          UiUtils.showError(controller.errorMessage.value);
        }
      },
    );
  }

  void _handlePresentAndPayment(
    int consulenteId,
    AttendanceController controller,
    bool hasCompanions,
  ) async {
    // Se não tiver acompanhantes, regista a presença com 1 pagamento.
    if (!hasCompanions) {
      controller.markAttendanceWithPayment(consulenteId, 'present', 1);
      return;
    }

    // Se tiver acompanhantes, pergunta no BottomSheet quantos pagam.
    int paymentCount = 1; // Pelo menos o consulente

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetTheme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: sheetTheme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registar Pagamento',
                    style: sheetTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Este consulente tem acompanhantes na sessão. Quantas pessoas irão pagar a sessão?',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: paymentCount > 0
                            ? () => setState(() => paymentCount--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline, size: 36),
                        color: sheetTheme.colorScheme.primary,
                      ),
                      const SizedBox(width: 20),
                      Text(
                        paymentCount.toString(),
                        style: sheetTheme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () => setState(() => paymentCount++),
                        icon: const Icon(Icons.add_circle_outline, size: 36),
                        color: sheetTheme.colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        controller.markAttendanceWithPayment(
                          consulenteId,
                          'present',
                          paymentCount,
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Confirmar Presença e Pagamento'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
