import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/consulente_controller.dart';
import '../models/consulente.dart';
import '../widgets/standard_appbar.dart';

class ConsulenteFormScreen extends StatefulWidget {
  final Consulente? consulente;

  const ConsulenteFormScreen({super.key, this.consulente});

  @override
  State<ConsulenteFormScreen> createState() => _ConsulenteFormScreenState();
}

class _ConsulenteFormScreenState extends State<ConsulenteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  late ConsulentesController controller;
  bool get isEditing => widget.consulente != null;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ConsulentesController>();
    
    if (isEditing) {
      _nameController.text = widget.consulente!.name;
      _phoneController.text = widget.consulente!.phone;
      _emailController.text = widget.consulente!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: StandardAppBar(
        title: isEditing ? 'Editar consulente' : 'Novo consulente',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _saveConsulente,
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
            _buildNameField(),
            const SizedBox(height: 16),
            _buildPhoneField(),
            const SizedBox(height: 16),
            _buildEmailField(),
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
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            radius: 30,
            child: Icon(
              isEditing ? Icons.edit : Icons.person_add,
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
                  isEditing ? 'Editar consulente' : 'Novo consulente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Atualize as informações do consulente'
                      : 'Preencha os dados do novo consulente',
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

  Widget _buildNameField() {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Nome *',
        hintText: 'Nome completo do consulente',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nome é obrigatório';
        }
        return null;
      },
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildPhoneField() {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'Telefone *',
        hintText: '(351) 999999999',
        prefixIcon: const Icon(Icons.phone),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Telefone é obrigatório';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'email@exemplo.com',
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (!GetUtils.isEmail(value)) {
            return 'Email inválido';
          }
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    final theme = Theme.of(context);
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: controller.isLoading.value ? null : _saveConsulente,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: controller.isLoading.value
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                  ),
                )
              : Text(
                  isEditing ? 'Atualizar consulente' : 'Criar consulente',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    });
  }

  Future<void> _saveConsulente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final consulente = Consulente(
      id: widget.consulente?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      notes: null, // Removido campo de notas
    );

    bool success;
    if (isEditing) {
      success = await controller.updateConsulente(consulente);
    } else {
      success = await controller.createConsulente(consulente);
    }

    if (success) {
      Get.back();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Consulente atualizado com sucesso' : 'Consulente criado com sucesso',
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
              controller.errorMessage.value,
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
