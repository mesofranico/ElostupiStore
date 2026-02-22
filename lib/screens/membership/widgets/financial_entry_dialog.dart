import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/finance_controller.dart';
import '../../../models/financial_record.dart';
import '../../../core/app_style.dart';
import '../../../core/utils/ui_utils.dart';
import '../membership_utils.dart';

class FinancialEntryDialog {
  static void show(BuildContext context, {String initialType = 'expense'}) {
    final financeController = Get.find<FinanceController>();

    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = initialType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              (selectedType == 'income'
                                      ? Colors.green
                                      : Colors.red)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          selectedType == 'income'
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: selectedType == 'income'
                              ? Colors.green
                              : Colors.red,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedType == 'income'
                                  ? 'Nova Entrada'
                                  : 'Novo Gasto',
                              style: AppStyle.titleStyle,
                            ),
                            Text(
                              'Registe um movimento financeiro manual',
                              style: AppStyle.subtitleStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Tipo de Registo
                  Row(
                    children: [
                      Expanded(
                        child: _TypeButton(
                          label: 'ENTRADA',
                          icon: Icons.add_circle_outline,
                          color: Colors.green,
                          isSelected: selectedType == 'income',
                          onTap: () => setState(() => selectedType = 'income'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TypeButton(
                          label: 'GASTO / SAÍDA',
                          icon: Icons.remove_circle_outline,
                          color: Colors.red,
                          isSelected: selectedType == 'expense',
                          onTap: () => setState(() => selectedType = 'expense'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: 'Categoria (ex: Luz, Mercearia, Limpeza) *',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Valor (€) *',
                      prefixIcon: const Icon(Icons.euro_symbol_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Data do Gasto
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Data: ${MembershipUtils.formatDate(selectedDate)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descrição / Notas (opcional)',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final category = categoryController.text.trim();
                            final amountStr = amountController.text
                                .trim()
                                .replaceAll(',', '.');
                            final amount = double.tryParse(amountStr);

                            if (category.isEmpty ||
                                amount == null ||
                                amount <= 0) {
                              UiUtils.showError(
                                'Preencha os campos obrigatórios corretamente.',
                              );
                              return;
                            }

                            final record = FinancialRecord(
                              type: selectedType,
                              category: category,
                              amount: amount,
                              description: descriptionController.text.trim(),
                              recordDate: selectedDate,
                            );

                            final success = await financeController.addRecord(
                              record,
                            );
                            if (success && context.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedType == 'income'
                                ? Colors.green
                                : Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Guardar Registo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
