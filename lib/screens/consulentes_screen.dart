import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/consulente_controller.dart';
import '../models/consulente.dart';
import '../models/consulente_session.dart';
import '../widgets/standard_appbar.dart';
import 'consulente_form_screen.dart';
import 'consulente_detail_screen.dart';

void _showNewConsulenteBottomSheet(BuildContext context, ConsulentesController controller) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _NewConsulenteBottomSheet(controller: controller),
    ),
  );
}

class ConsulentesScreen extends StatelessWidget {
  const ConsulentesScreen({super.key});

  Future<Map<String, dynamic>> _getConsulenteData(int consulenteId, ConsulentesController controller) async {
    final sessionCount = await controller.getSessionCount(consulenteId);
    final lastSession = await controller.getLastSession(consulenteId);
    
    return {
      'sessionCount': sessionCount,
      'lastSession': lastSession,
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Ontem';
    } else if (difference < 7) {
      return 'Há $difference dias';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteDialog(Consulente consulente, ConsulentesController controller) {
    final theme = Get.context != null ? Theme.of(Get.context!) : null;
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar consulente'),
        content: Text('Tem a certeza que deseja eliminar ${consulente.name}?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await controller.deleteConsulente(consulente.id!);
              if (Get.context == null) return;
              if (success) {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Consulente eliminado com sucesso',
                      style: TextStyle(color: theme?.colorScheme.onPrimary ?? Colors.white),
                    ),
                    backgroundColor: theme?.colorScheme.primary ?? Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  SnackBar(
                    content: Text(
                      controller.errorMessage.value,
                      style: TextStyle(color: theme?.colorScheme.onError ?? Colors.white),
                    ),
                    backgroundColor: theme?.colorScheme.error ?? Colors.red,
                  ),
                );
              }
            },
            child: Text('Eliminar', style: TextStyle(color: theme?.colorScheme.error ?? Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ConsulentesController controller = Get.find<ConsulentesController>();

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Gestão de Consulentes',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: () => controller.refreshData(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
          IconButton(
            onPressed: () => _showNewConsulenteBottomSheet(context, controller),
            icon: const Icon(Icons.add),
            tooltip: 'Novo consulente',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  controller.errorMessage.value,
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => controller.loadConsulentes(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildSearchBar(context, controller),
            _buildStatistics(context, controller),
            Expanded(
              child: _buildConsulentesList(context, controller),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSearchBar(BuildContext context, ConsulentesController controller) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        onChanged: (value) => controller.updateSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Pesquisar por nome, telefone ou email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () => controller.clearSearch(),
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, ConsulentesController controller) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, int>>(
      future: controller.getStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(child: _buildStatCard(context, 'Total', '—', theme.colorScheme.primary)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard(context, 'Com Sessões', '—', Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard(context, 'Sessões Recentes', '—', Colors.orange)),
              ],
            ),
          );
        }

        final stats = snapshot.data ?? {
          'total': 0,
          'withSessions': 0,
          'recentSessions': 0,
        };

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(child: _buildStatCard(context, 'Total', stats['total']!.toString(), theme.colorScheme.primary)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(context, 'Com Sessões', stats['withSessions']!.toString(), Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(context, 'Sessões Recentes', stats['recentSessions']!.toString(), Colors.orange)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 0)),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
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
          ),
        ],
      ),
    );
  }

  Widget _buildConsulentesList(BuildContext context, ConsulentesController controller) {
    final theme = Theme.of(context);
    final filteredConsulentes = controller.filteredConsulentes;

    if (filteredConsulentes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              controller.searchQuery.isNotEmpty
                  ? 'Nenhum consulente encontrado'
                  : 'Nenhum consulente registado',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (controller.searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Toque em «Novo consulente» na barra superior para adicionar',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: filteredConsulentes.length,
      itemBuilder: (context, index) {
        final consulente = filteredConsulentes[index];
        return _buildConsulenteCard(context, consulente, controller);
      },
    );
  }

  Widget _buildConsulenteCard(BuildContext context, Consulente consulente, ConsulentesController controller) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _getConsulenteData(consulente.id!, controller),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
            child: const ListTile(
              leading: CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
              title: Text('A carregar...'),
              subtitle: Text('A obter dados da sessão'),
            ),
          );
        }

        final sessionCount = snapshot.data?['sessionCount'] ?? 0;
        final lastSession = snapshot.data?['lastSession'] as ConsulenteSession?;

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
              onTap: () => Get.to(() => ConsulenteDetailScreen(consulente: consulente)),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        consulente.name.isNotEmpty ? consulente.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consulente.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          sessionCount > 0
                              ? Row(
                                  children: [
                                    Icon(Icons.event, size: 14, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$sessionCount ${sessionCount == 1 ? 'sessão' : 'sessões'}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (lastSession != null) ...[
                                      const SizedBox(width: 12),
                                      Icon(Icons.schedule, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Última: ${_formatDate(lastSession.sessionDate)}',
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ],
                                )
                              : Text(
                                  'Sem sessões marcadas',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            Get.to(() => ConsulenteDetailScreen(consulente: consulente));
                            break;
                          case 'edit':
                            Get.to(() => ConsulenteFormScreen(consulente: consulente));
                            break;
                          case 'delete':
                            _showDeleteDialog(consulente, controller);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 20),
                              SizedBox(width: 8),
                              Text('Ver detalhes'),
                            ],
                          ),
                        ),
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
                      child: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NewConsulenteBottomSheet extends StatefulWidget {
  final ConsulentesController controller;

  const _NewConsulenteBottomSheet({required this.controller});

  @override
  State<_NewConsulenteBottomSheet> createState() => _NewConsulenteBottomSheetState();
}

class _NewConsulenteBottomSheetState extends State<_NewConsulenteBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final consulente = Consulente(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      notes: null,
    );
    final success = await widget.controller.createConsulente(consulente);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Consulente criado com sucesso',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage.value,
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      radius: 22,
                      child: Icon(
                        Icons.person_add,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Novo consulente',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Preencha os dados do novo consulente',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
                  child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nome *',
                          hintText: 'Nome completo do consulente',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Nome é obrigatório';
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Telefone *',
                          hintText: '(351) 999999999',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Telefone é obrigatório';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'email@exemplo.com',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v != null && v.isNotEmpty && !GetUtils.isEmail(v)) return 'Email inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Obx(() {
                        return SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: widget.controller.isLoading.value ? null : _save,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: widget.controller.isLoading.value
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                                    ),
                                  )
                                : const Text('Criar consulente'),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
