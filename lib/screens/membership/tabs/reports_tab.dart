import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/member_controller.dart';
import '../../../controllers/payment_controller.dart';
import '../../../controllers/finance_controller.dart';
import '../../../models/financial_record.dart';
import '../../../core/currency_formatter.dart';
import '../widgets/financial_entry_dialog.dart';
import '../membership_utils.dart';
import '../../../core/app_style.dart';

class ReportsTab extends StatefulWidget {
  final MemberController memberController;
  final PaymentController paymentController;

  const ReportsTab({
    super.key,
    required this.memberController,
    required this.paymentController,
  });

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  late final FinanceController financeController;

  @override
  void initState() {
    super.initState();
    financeController = Get.find<FinanceController>();
    // Auto-refresh ao entrar na aba/ecrã
    WidgetsBinding.instance.addPostFrameCallback((_) {
      financeController.loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Moderno
          _buildHeader(theme, financeController),

          const SizedBox(height: 24),

          // Filtros Rápidos
          _buildQuickFilters(theme, financeController),

          const SizedBox(height: 24),

          // Cards Principais (Balanço)
          _buildSummaryCards(theme, financeController),

          const SizedBox(height: 28),

          // Secção de Ações
          _buildActionButtons(
            context,
            theme,
            widget.memberController,
            widget.paymentController,
          ),

          const SizedBox(height: 32),

          // Lista de Transações Recentes
          _buildTransactionsSection(theme, financeController),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, FinanceController financeController) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppStyle.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Consolidado',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Obx(
                  () => Text(
                    CurrencyFormatter.formatEuro(financeController.balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => financeController.isLoading.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : IconButton(
                    onPressed: () => financeController.loadAllData(),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(
    ThemeData theme,
    FinanceController financeController,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _FilterChip(
          label: 'Hoje',
          type: 'daily',
          controller: financeController,
        ),
        _FilterChip(
          label: 'Semana',
          type: 'weekly',
          controller: financeController,
        ),
        _FilterChip(
          label: 'Mês',
          type: 'monthly',
          controller: financeController,
        ),
        IconButton.filledTonal(
          onPressed: () =>
              _showCustomDateRangePicker(Get.context!, financeController),
          icon: const Icon(Icons.date_range_rounded, size: 20),
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(
    ThemeData theme,
    FinanceController financeController,
  ) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Entradas',
            icon: Icons.arrow_upward_rounded,
            color: Colors.green,
            value: Obx(
              () => Text(
                CurrencyFormatter.formatEuro(financeController.totalIncome),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Gastos',
            icon: Icons.arrow_downward_rounded,
            color: Colors.red,
            value: Obx(
              () => Text(
                CurrencyFormatter.formatEuro(financeController.totalExpense),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    MemberController mCtrl,
    PaymentController pCtrl,
  ) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => FinancialEntryDialog.show(context),
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
            label: const Text('Novo Gasto'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () =>
                FinancialEntryDialog.show(context, initialType: 'income'),
            icon: const Icon(Icons.add_chart_rounded, size: 20),
            label: const Text('Nova Entrada'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              foregroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection(
    ThemeData theme,
    FinanceController financeController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transações Recentes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {}, // Link para histórico completo futuramente
              child: const Text('Ver tudo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (financeController.records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: theme.disabledColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma transação manual no período',
                      style: TextStyle(color: theme.disabledColor),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: financeController.records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final record = financeController.records[index];
              final isIncome = record.type == 'income';

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showTransactionDetails(context, record, theme),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isIncome ? Colors.green : Colors.red)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isIncome
                                ? Icons.keyboard_double_arrow_up_rounded
                                : Icons.keyboard_double_arrow_down_rounded,
                            color: isIncome ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                MembershipUtils.formatDate(record.recordDate),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isIncome ? '+' : '-'} ${CurrencyFormatter.formatEuro(record.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isIncome ? Colors.green : Colors.red,
                              ),
                            ),
                            if (record.id != null)
                              GestureDetector(
                                onTap: () =>
                                    financeController.deleteRecord(record.id!),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.error.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        size: 14,
                                        color: theme.colorScheme.error,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Eliminar',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  void _showCustomDateRangePicker(
    BuildContext context,
    FinanceController controller,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: controller.startDate.value,
        end: controller.endDate.value,
      ),
    );
    if (picked != null) {
      controller.setDateRange(picked.start, picked.end);
    }
  }

  void _showTransactionDetails(
    BuildContext context,
    FinancialRecord record,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
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
                          (record.type == 'income' ? Colors.green : Colors.red)
                              .withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      record.type == 'income'
                          ? Icons.keyboard_double_arrow_up_rounded
                          : Icons.keyboard_double_arrow_down_rounded,
                      color: record.type == 'income'
                          ? Colors.green
                          : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.category,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          MembershipUtils.formatDate(record.recordDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${record.type == 'income' ? '+' : '-'} ${CurrencyFormatter.formatEuro(record.amount)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: record.type == 'income'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (record.description != null &&
                  record.description!.isNotEmpty) ...[
                Text(
                  'Descrição',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record.description!
                      .replaceAll('(overdue)', '(Em Atraso)')
                      .replaceAll('(regular)', '(Mensal)')
                      .replaceAll('(advance)', '(Adiantado)'),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
              ],
              if (record.details != null &&
                  record.details!.containsKey('items')) ...[
                Text(
                  'Produtos/Serviços',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...(record.details!['items'] as List).map((item) {
                  final it = Map<String, dynamic>.from(item);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${it['quantity']}x ${it['name']}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatEuro(
                            double.parse((it['price'] ?? 0).toString()) *
                                double.parse((it['quantity'] ?? 1).toString()),
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
              if (record.details != null &&
                  record.details!.containsKey('memberName')) ...[
                Text(
                  'Relacionado a:',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      record.details!['memberName'],
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
                if (record.details!.containsKey('paymentType')) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.payment_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tipo: ${MembershipUtils.getPaymentTypeText(record.details!['paymentType'])}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(modalContext),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Fechar'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String type;
  final FinanceController controller;

  const _FilterChip({
    required this.label,
    required this.type,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = controller.selectedPeriodType.value == type;
      return FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => controller.setPeriod(type),
        selectedColor: Get.theme.colorScheme.primaryContainer,
        checkmarkColor: Get.theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected
              ? Get.theme.colorScheme.primary
              : Get.theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget value;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Get.theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Get.theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: Get.theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          value,
        ],
      ),
    );
  }
}
