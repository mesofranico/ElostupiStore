import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/consulente_controller.dart';
import '../models/consulente_session.dart';
import '../models/consulente.dart';
import '../widgets/standard_appbar.dart';

class ConsulenteSessionFormScreen extends StatefulWidget {
  final int consulenteId;
  final ConsulenteSession? session;

  const ConsulenteSessionFormScreen({
    super.key,
    required this.consulenteId,
    this.session,
  });

  @override
  State<ConsulenteSessionFormScreen> createState() =>
      _ConsulenteSessionFormScreenState();
}

class _ConsulenteSessionFormScreenState
    extends State<ConsulenteSessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  ConsulentesController? controller;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<int> _selectedAcompanhantes = [];
  int _extraAcompanhantes = 0;
  bool get isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();

    try {
      controller = Get.find<ConsulentesController>();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao inicializar formulário de sessão',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      Get.back();
      return;
    }

    if (isEditing) {
      _selectedDate = widget.session!.sessionDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.session!.sessionDate);
      _notesController.text = widget.session!.notes ?? '';
      _selectedAcompanhantes = widget.session!.acompanhantesIds ?? [];
      _extraAcompanhantes = widget.session!.extraAcompanhantes;
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = const TimeOfDay(hour: 20, minute: 0);
      _selectedAcompanhantes = [];
      _extraAcompanhantes = 0;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || _selectedDate == null || _selectedTime == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: StandardAppBar(
        title: isEditing ? 'Editar sessão' : 'Nova sessão',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _saveSession,
            child: Text(
              'Guardar',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDateTimeFields(),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 16),
            _buildAcompanhantesField(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            radius: 30,
            child: Icon(
              isEditing ? Icons.edit_calendar : Icons.event,
              color: theme.colorScheme.onPrimaryContainer,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Editar sessão' : 'Nova sessão',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Atualize os detalhes da sessão'
                      : 'Registe uma nova sessão de consulta (hora padrão: 20:00)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeFields() {
    return Column(
      children: [
        _buildDateField(),
        const SizedBox(height: 16),
        _buildTimeField(),
      ],
    );
  }

  Widget _buildDateField() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data da sessão',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hora da sessão',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedTime!.format(context),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Notas adicionais',
        prefixIcon: const Icon(Icons.note),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4,
        ),
      ),
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildSaveButton() {
    final theme = Theme.of(context);
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: controller!.isLoading.value ? null : _saveSession,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: controller!.isLoading.value
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(
                  isEditing ? 'Atualizar sessão' : 'Criar sessão',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime!,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sessionDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final session = ConsulenteSession(
      id: widget.session?.id,
      consulenteId: widget.consulenteId,
      sessionDate: sessionDateTime,
      description: _notesController.text.trim().isEmpty
          ? 'Sessão de consulta'
          : _notesController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      acompanhantesIds: _selectedAcompanhantes.isEmpty
          ? null
          : _selectedAcompanhantes,
      extraAcompanhantes: _extraAcompanhantes,
    );

    bool success;
    if (isEditing) {
      success = await controller!.updateSession(session);
    } else {
      success = await controller!.createSession(session);
    }

    if (success) {
      Get.back();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Sessão atualizada com sucesso'
                  : 'Sessão criada com sucesso',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller!.errorMessage.value,
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildAcompanhantesField() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acompanhantes',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selecionar consulentes acompanhantes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAcompanhantesBottomSheet,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (_selectedAcompanhantes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedAcompanhantes.map((id) {
                    final consulente = controller!.consulentes.firstWhere(
                      (c) => c.id == id,
                      orElse: () => controller!.consulentes.first,
                    );
                    return Chip(
                      label: Text(consulente.name),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedAcompanhantes.remove(id);
                        });
                      },
                      backgroundColor: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.6),
                      deleteIconColor: theme.colorScheme.onPrimaryContainer,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acompanhantes não registados',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Número de pessoas extras',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: _extraAcompanhantes > 0
                              ? () {
                                  setState(() {
                                    _extraAcompanhantes--;
                                  });
                                }
                              : null,
                          color: theme.colorScheme.primary,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '$_extraAcompanhantes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () {
                            setState(() {
                              _extraAcompanhantes++;
                            });
                          },
                          color: theme.colorScheme.primary,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAcompanhantesBottomSheet() {
    final availableConsulentes = controller!.consulentes
        .where(
          (c) =>
              c.id != widget.consulenteId &&
              !_selectedAcompanhantes.contains(c.id),
        )
        .toList();

    if (availableConsulentes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não há consulentes disponíveis para adicionar como acompanhantes',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AcompanhantesSelectionBottomSheet(
        availableConsulentes: availableConsulentes,
        onConsulenteSelected: (consulente) {
          setState(() {
            if (consulente.id != null) {
              _selectedAcompanhantes.add(consulente.id!);
            }
          });
        },
      ),
    );
  }
}

class AcompanhantesSelectionBottomSheet extends StatefulWidget {
  final List<Consulente> availableConsulentes;
  final Function(Consulente) onConsulenteSelected;

  const AcompanhantesSelectionBottomSheet({
    super.key,
    required this.availableConsulentes,
    required this.onConsulenteSelected,
  });

  @override
  State<AcompanhantesSelectionBottomSheet> createState() =>
      _AcompanhantesSelectionBottomSheetState();
}

class _AcompanhantesSelectionBottomSheetState
    extends State<AcompanhantesSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Consulente> _filteredConsulentes = [];

  @override
  void initState() {
    super.initState();
    _filteredConsulentes = widget.availableConsulentes;
    _searchController.addListener(_filterConsulentes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterConsulentes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredConsulentes = widget.availableConsulentes;
      } else {
        _filteredConsulentes = widget.availableConsulentes.where((consulente) {
          return consulente.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.group_add,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Selecionar acompanhantes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredConsulentes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum consulente encontrado',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredConsulentes.length,
                    itemBuilder: (context, index) {
                      final consulente = _filteredConsulentes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withValues(
                                alpha: 0.06,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              consulente.name.isNotEmpty
                                  ? consulente.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            consulente.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Icon(
                            Icons.add_circle_outline,
                            color: theme.colorScheme.primary,
                          ),
                          onTap: () {
                            widget.onConsulenteSelected(consulente);
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
