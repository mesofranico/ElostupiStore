import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/consulente_controller.dart';
import '../models/consulente.dart';
import '../models/consulente_session.dart';
import '../services/attendance_service.dart';
import '../widgets/standard_appbar.dart';
import 'consulente_form_screen.dart';
import 'consulente_session_form_screen.dart';

class ConsulenteDetailScreen extends StatefulWidget {
  final Consulente consulente;

  const ConsulenteDetailScreen({super.key, required this.consulente});

  @override
  State<ConsulenteDetailScreen> createState() => _ConsulenteDetailScreenState();
}

class _ConsulenteDetailScreenState extends State<ConsulenteDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Carregar sessões após o widget ser construído
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ConsulentesController controller = Get.find<ConsulentesController>();
      controller.selectConsulente(widget.consulente);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ConsulentesController controller = Get.find<ConsulentesController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: StandardAppBar(
          title: widget.consulente.name,
          backgroundColor: theme.colorScheme.primary,
          showBackButton: true,
          bottom: TabBar(
            indicatorColor: theme.colorScheme.onPrimary,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Informações'),
              Tab(icon: Icon(Icons.event), text: 'Histórico'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, controller),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(controller),
            _buildHistoryTab(controller),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addNewSession(controller),
          backgroundColor: theme.colorScheme.primary,
          child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildInfoTab(ConsulentesController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConsulenteCard(),
          const SizedBox(height: 24),
          _buildQuickStats(controller),
          const SizedBox(height: 24),
          _buildRecentSessions(controller),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ConsulentesController controller) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final sessions = controller.sessions;

      if (sessions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 56, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                'Nenhuma sessão registada',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Toque no botão + para adicionar a primeira sessão',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _buildSessionCard(session, controller);
        },
      );
    });
  }

  Widget _buildConsulenteCard() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 0)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  radius: 30,
                  child: Text(
                    widget.consulente.name.isNotEmpty ? widget.consulente.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.consulente.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            widget.consulente.phone,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      if (widget.consulente.email != null && widget.consulente.email!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.email, size: 16, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.consulente.email!,
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Registado em ${_formatDate(widget.consulente.createdAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ConsulentesController controller) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _getConsulenteStats(widget.consulente.id!, controller),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final sessionCount = snapshot.data?['sessionCount'] ?? 0;
        final lastSession = snapshot.data?['lastSession'] as ConsulenteSession?;

        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
              BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 0)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estatísticas',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total de Sessões',
                      sessionCount.toString(),
                      Icons.event,
                    ),
                    if (lastSession != null)
                      _buildStatItem(
                        'Última Sessão',
                        _formatDate(lastSession.sessionDate),
                        Icons.schedule,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentSessions(ConsulentesController controller) {
    final theme = Theme.of(context);
    final recentSessions = controller.sessions.take(3).toList();

    if (recentSessions.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 48, color: theme.colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma sessão registada',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toque no botão + para adicionar a primeira sessão',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 0)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sessões recentes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...recentSessions.map((session) => _buildSessionPreview(session)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionPreview(ConsulenteSession session) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(session.sessionDate),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            session.description,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(ConsulenteSession session, ConsulentesController controller) {
    return FutureBuilder<String?>(
      future: _getAttendanceStatus(session),
      builder: (context, snapshot) {
        final attendanceStatus = snapshot.data;
        
        // Se não há registo de presença, não exibir a sessão
        if (attendanceStatus == null) {
          return const SizedBox.shrink();
        }
        
        Color statusColor;
        IconData statusIcon;
        String statusText;
        
        switch (attendanceStatus) {
          case 'present':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            statusText = 'Presente';
            break;
          case 'absent':
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            statusText = 'Faltou';
            break;
          case 'pending':
            statusColor = Colors.orange;
            statusIcon = Icons.schedule;
            statusText = 'Pendente';
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.help_outline;
            statusText = 'Sem registo';
        }

        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
              BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 0)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _editSession(session),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateTime(session.sessionDate),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                session.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleSessionMenuAction(value, session, controller),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.more_vert,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (session.notes != null && session.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          session.notes!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String?> _getAttendanceStatus(ConsulenteSession session) async {
    try {
      // Buscar registos de presença para esta data
      final attendanceRecords = await AttendanceService.getAttendanceByDate(session.sessionDate);
      
      // Procurar o registo para este consulente
      final record = attendanceRecords.firstWhereOrNull(
        (record) => record.consulenteId == widget.consulente.id,
      );
      
      return record?.status;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar status de presença: $e');
      }
      return null;
    }
  }

  void _handleMenuAction(String action, ConsulentesController controller) {
    switch (action) {
      case 'edit':
        _editConsulente();
        break;
      case 'delete':
        _showDeleteDialog(controller);
        break;
    }
  }

  void _handleSessionMenuAction(String action, ConsulenteSession session, ConsulentesController controller) {
    switch (action) {
      case 'edit':
        _editSession(session);
        break;
    }
  }

  void _editConsulente() {
    if (widget.consulente.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não é possível editar consulente: ID não encontrado',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    Get.to(() => ConsulenteFormScreen(consulente: widget.consulente));
  }

  void _editSession(ConsulenteSession session) {
    if (widget.consulente.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não é possível editar sessão: ID do consulente não encontrado',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    Get.to(() => ConsulenteSessionFormScreen(
      consulenteId: widget.consulente.id!,
      session: session,
    ));
  }

  void _addNewSession(ConsulentesController controller) {
    if (widget.consulente.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não é possível adicionar sessão: ID do consulente não encontrado',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    Get.to(() => ConsulenteSessionFormScreen(consulenteId: widget.consulente.id!));
  }

  void _showDeleteDialog(ConsulentesController controller) {
    final theme = Theme.of(context);
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar consulente'),
        content: Text('Tem a certeza que deseja eliminar ${widget.consulente.name}?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await controller.deleteConsulente(widget.consulente.id!);
              if (success) {
                Get.back();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Consulente eliminado com sucesso',
                        style: TextStyle(color: theme.colorScheme.onPrimary),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        controller.errorMessage.value,
                        style: TextStyle(color: theme.colorScheme.onError),
                      ),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text('Eliminar', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getConsulenteStats(int consulenteId, ConsulentesController controller) async {
    final sessionCount = await controller.getSessionCount(consulenteId);
    final lastSession = await controller.getLastSession(consulenteId);
    
    return {
      'sessionCount': sessionCount,
      'lastSession': lastSession,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} às ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
