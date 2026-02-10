import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/electricity_controller.dart';
import '../core/currency_formatter.dart';
import '../widgets/standard_appbar.dart';

class ElectricityReadingScreen extends StatelessWidget {
  const ElectricityReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ElectricityController controller = Get.put(ElectricityController());

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Contagem de Luz',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/electricity/settings'),
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: Column(
        children: [
          Focus(
            focusNode: controller.unfocusNode,
            child: const SizedBox.shrink(),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nova leitura',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.counterController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Valor do contador',
                    hintText: 'Ex: 1500',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    prefixIcon: Icon(Icons.electric_bolt, color: theme.colorScheme.primary),
                    helperText: controller.readings.isEmpty
                        ? 'Primeira leitura - valor inicial do contador'
                        : 'Apenas números inteiros',
                    suffixIcon: controller.getLastCounterValue() != null
                        ? Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              'Último: ${controller.getLastCounterValue()!.toInt()}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  if (controller.settings.value != null) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.euro, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Preço atual por KW',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatEuroWithSeparator(controller.settings.value!.defaultPricePerKw),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.notesController,
                  maxLines: 1,
                  decoration: InputDecoration(
                    labelText: 'Observações (opcional)',
                    hintText: 'Adicione observações sobre a leitura',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    prefixIcon: Icon(Icons.note, color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => FilledButton(
                    onPressed: controller.isAdding.value ? null : controller.addReading,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: controller.isAdding.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Adicionar leitura',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                  )),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.readings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.electric_bolt_outlined,
                        size: 56,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma leitura registada',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: controller.readings.length,
                itemBuilder: (context, index) {
                  final reading = controller.readings[index];
                  final totalWithVAT = controller.calculateTotalWithVAT(reading.totalCost);
                  
final theme = Theme.of(context);
                  return GestureDetector(
                    onDoubleTap: () => _showDeleteDialog(context, controller, reading.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 0)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.electric_bolt,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: reading.kwConsumed == 0
                                              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                                              : theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          reading.kwConsumed == 0 ? 'Inicial' : '${reading.kwConsumed.toInt()} KW',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: reading.kwConsumed == 0
                                                ? theme.colorScheme.onSurfaceVariant
                                                : theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: reading.kwConsumed == 0
                                              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                                              : Colors.green.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          reading.kwConsumed == 0 ? '€0.00' : CurrencyFormatter.formatEuroWithSeparator(totalWithVAT),
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: reading.kwConsumed == 0 ? theme.colorScheme.onSurfaceVariant : Colors.green.shade800,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        controller.formatDate(reading.readingDate),
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.euro, size: 10, color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${CurrencyFormatter.formatEuroWithSeparator(reading.pricePerKw)}/KW',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.receipt, size: 10, color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 2),
                                      Text(
                                        'IVA ${controller.settings.value?.vatRate.toStringAsFixed(1) ?? '23.0'}%',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        controller.formatTime(reading.readingDate),
                                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  if (reading.notes.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.note, size: 10, color: theme.colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            reading.notes,
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Duplo toque para excluir',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 10,
                                        color: theme.colorScheme.outline,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ElectricityController controller, int id) {
    final theme = Theme.of(context);
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem a certeza que deseja excluir esta leitura?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteReading(id);
            },
            child: Text('Excluir', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }
} 