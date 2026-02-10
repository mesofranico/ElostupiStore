import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/electricity_controller.dart';
import '../services/electricity_service.dart';
import '../core/currency_formatter.dart';
import '../widgets/standard_appbar.dart';

class ElectricitySettingsScreen extends StatelessWidget {
  const ElectricitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ElectricityController controller = Get.find<ElectricityController>();
    final priceController = TextEditingController();
    final vatController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.settings.value != null) {
        priceController.text = controller.settings.value!.defaultPricePerKw.toStringAsFixed(4);
        vatController.text = controller.settings.value!.vatRate.toStringAsFixed(1);
      }
    });

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Configurações de eletricidade',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configurações padrão',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Defina os valores padrão para preço por KW e IVA',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                  BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 0)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valores padrão',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Preço por KW (€)',
                      hintText: 'Ex: 0.1500',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      prefixIcon: Icon(Icons.euro, color: theme.colorScheme.primary),
                      helperText: 'Preço padrão por quilowatt-hora',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: vatController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Taxa de IVA (%)',
                      hintText: 'Ex: 23.0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      prefixIcon: Icon(Icons.percent, color: theme.colorScheme.primary),
                      helperText: 'Taxa de IVA aplicada aos custos',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        try {
                          final price = double.parse(priceController.text);
                          final vat = double.parse(vatController.text);
                          if (price < 0 || vat < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Os valores devem ser positivos',
                                  style: TextStyle(color: theme.colorScheme.onError),
                                ),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                            return;
                          }
                          await ElectricityService.updateSettings(
                            defaultPricePerKw: price,
                            vatRate: vat,
                          );
                          await controller.loadSettings();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Configurações atualizadas com sucesso',
                                  style: TextStyle(color: theme.colorScheme.onPrimary),
                                ),
                                backgroundColor: theme.colorScheme.primary,
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Falha ao atualizar configurações: $e',
                                  style: TextStyle(color: theme.colorScheme.onError),
                                ),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Guardar configurações',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (controller.settings.value == null) return const SizedBox.shrink();
              final settings = controller.settings.value!;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configurações atuais',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            'Preço/KW',
                            CurrencyFormatter.formatEuroWithSeparator(settings.defaultPricePerKw),
                            Icons.euro,
                            theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            'IVA',
                            '${settings.vatRate.toStringAsFixed(1)}%',
                            Icons.percent,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Última atualização: ${_formatDate(settings.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 