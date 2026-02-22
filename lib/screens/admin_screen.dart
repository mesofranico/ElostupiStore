import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/standard_appbar.dart';
import '../controllers/admin_controller.dart';
import '../core/utils/ui_utils.dart';
import '../services/settings_service.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Administração',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          _buildMenuCard(
            context,
            icon: Icons.inventory,
            title: 'Gestão de Produtos',
            subtitle: 'Adicionar, editar e remover produtos da loja',
            onTap: () => Get.toNamed('/admin/products'),
          ),
          _buildMenuCard(
            context,
            icon: Icons.people,
            title: 'Gestão de Consulentes',
            subtitle: 'Registar e acompanhar consulentes e consultas',
            onTap: () => Get.toNamed('/consulentes'),
          ),
          _buildMenuCard(
            context,
            icon: Icons.checklist,
            title: 'Marcação de presenças',
            subtitle: 'Marcar presenças e faltas por data',
            onTap: () => Get.toNamed('/attendance'),
          ),
          _buildMenuCard(
            context,
            icon: Icons.electric_bolt,
            title: 'Contagem de Luz',
            subtitle: 'Registar leituras e calcular custos',
            onTap: () => Get.toNamed('/electricity'),
          ),
          _buildMenuCard(
            context,
            icon: Icons.settings,
            title: 'Configurações Gerais',
            subtitle: 'Definir valor da sessão, etc.',
            onTap: () => _showSettingsDialog(context),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          _buildMenuCard(
            context,
            icon: Icons.delete_forever,
            title: 'Limpeza Completa do Sistema',
            subtitle: 'Reset as mensalidades, relatórios, presenças, etc.',
            iconColor: Colors.redAccent,
            onTap: () => _showResetPINDialog(context),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) async {
    final value = await SettingsService.getSetting('attendance_fee') ?? '3.50';
    final controller = TextEditingController(text: value);
    bool isLoading = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Configurações Gerais'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Defina o valor pago por pessoa (Sessão):'),
                const SizedBox(height: 15),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Valor da Sessão (€)',
                    border: OutlineInputBorder(),
                    prefixText: '€ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Get.back(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        final success = await SettingsService.updateSetting(
                          'attendance_fee',
                          controller.text.trim().replaceAll(',', '.'),
                        );
                        setState(() => isLoading = false);
                        if (success) {
                          Get.back();
                          UiUtils.showSuccess(
                            'Configuração guardada com sucesso!',
                          );
                        } else {
                          UiUtils.showError('Erro ao guardar a configuração.');
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetPINDialog(BuildContext context) {
    final TextEditingController pinController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Limpeza de Segurança'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Esta ação é irreversível e irá apagar todo o histórico.',
            ),
            const SizedBox(height: 15),
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'Insira o PIN de Admin',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text == '1989') {
                Get.back();
                _showFinalConfirmDialog(context);
              } else {
                UiUtils.showError('PIN incorreto. Acesso negado.');
              }
            },
            child: const Text('Confirmar PIN'),
          ),
        ],
      ),
    );
  }

  void _showFinalConfirmDialog(BuildContext context) {
    final adminController = Get.find<AdminController>();

    UiUtils.showConfirmDialog(
      title: 'ATENÇÃO: RESET TOTAL',
      message:
          'Tem a certeza que deseja realizar o reset completo? Isso irá apagar todos os pagamentos, relatórios, presenças, etc. Membros, Produtos e Consulentes serão preservados.',
      confirmLabel: 'SIM, RESETAR TUDO',
      icon: Icons.warning_amber_rounded,
      color: Colors.red,
      onConfirm: () async {
        final success = await adminController.resetSystem('1989');
        if (success) {
          // Atualizar todos os controladores para refletir o reset
          await adminController.refreshAllControllers();

          UiUtils.showSuccess('O sistema foi resetado com sucesso!');
        } else {
          UiUtils.showError(adminController.errorMessage.value);
        }
      },
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
