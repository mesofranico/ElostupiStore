import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/consulente_controller.dart';
import '../models/consulente_session.dart';
import '../models/consulente.dart';

class ConsulenteSessionFormScreen extends StatefulWidget {
  final int consulenteId;
  final ConsulenteSession? session;

  const ConsulenteSessionFormScreen({
    super.key,
    required this.consulenteId,
    this.session,
  });

  @override
  State<ConsulenteSessionFormScreen> createState() => _ConsulenteSessionFormScreenState();
}

class _ConsulenteSessionFormScreenState extends State<ConsulenteSessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  ConsulentesController? controller;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<int> _selectedAcompanhantes = [];
  bool get isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();
    
    try {
      controller = Get.find<ConsulentesController>();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao inicializar formulário de sessão'),
          backgroundColor: Colors.red,
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
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = const TimeOfDay(hour: 20, minute: 0);
      _selectedAcompanhantes = [];
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Sessão' : 'Nova Sessão'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveSession,
            child: const Text(
              'Guardar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green[100],
            radius: 30,
            child: Icon(
              isEditing ? Icons.edit_calendar : Icons.event,
              color: Colors.green[700],
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Editar Sessão' : 'Nova Sessão',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing 
                      ? 'Atualize os detalhes da sessão'
                      : 'Registe uma nova sessão de consulta (hora padrão: 20:00)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
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
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.green[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data da Sessão',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.green[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hora da Sessão',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedTime!.format(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Notas adicionais',
        prefixIcon: const Icon(Icons.note),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildSaveButton() {
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: controller!.isLoading.value ? null : _saveSession,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: controller!.isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  isEditing ? 'Atualizar Sessão' : 'Criar Sessão',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
      description: _notesController.text.trim().isEmpty ? 'Sessão de consulta' : _notesController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      acompanhantesIds: _selectedAcompanhantes.isEmpty ? null : _selectedAcompanhantes,
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
            content: Text(isEditing ? 'Sessão atualizada com sucesso' : 'Sessão criada com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller!.errorMessage.value),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAcompanhantesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acompanhantes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selecionar consulentes acompanhantes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAcompanhantesBottomSheet,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green[600],
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
                      backgroundColor: Colors.green[100],
                      deleteIconColor: Colors.green[700],
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showAcompanhantesBottomSheet() {
    final availableConsulentes = controller!.consulentes
        .where((c) => c.id != widget.consulenteId && !_selectedAcompanhantes.contains(c.id))
        .toList();

    if (availableConsulentes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há consulentes disponíveis para adicionar como acompanhantes'),
          backgroundColor: Colors.blue,
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
  State<AcompanhantesSelectionBottomSheet> createState() => _AcompanhantesSelectionBottomSheetState();
}

class _AcompanhantesSelectionBottomSheetState extends State<AcompanhantesSelectionBottomSheet> {
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle do BottomSheet
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Cabeçalho
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.group_add,
                  color: Colors.green[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Selecionar Acompanhantes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
          // Campo de pesquisa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lista de consulentes
          Expanded(
            child: _filteredConsulentes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum consulente encontrado',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.green[100],
                            child: Text(
                              consulente.name.isNotEmpty ? consulente.name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            consulente.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Icon(
                            Icons.add_circle_outline,
                            color: Colors.green[600],
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
