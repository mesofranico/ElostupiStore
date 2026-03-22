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

          // Cards Principais (Balanço c/ Ações)
          _buildSummaryCards(context, theme, financeController),

          const SizedBox(height: 24),

          // Detalhamento de Entradas
          _buildIncomeBreakdown(theme, financeController),

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

  Widget _buildIncomeBreakdown(
    ThemeData theme,
    FinanceController financeController,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppStyle.cardDecoration(
        color: theme.colorScheme.surface,
        showShadow: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumo das Receitas',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            final report = financeController.consolidatedReport['income'] ?? {};
            final membership = (report['membership'] ?? 0).toDouble();
            final sales = (report['sales'] ?? 0).toDouble();
            final sessions = (report['sessions'] ?? 0).toDouble();
            final other = (report['other'] ?? 0).toDouble();

            return Column(
              children: [
                _buildBreakdownItem(
                  'Mensalidades',
                  membership,
                  Colors.blue,
                  Icons.person_outline_rounded,
                ),
                const Divider(height: 24, thickness: 0.5),
                _buildBreakdownItem(
                  'Venda de Produtos',
                  sales,
                  Colors.orange,
                  Icons.shopping_bag_outlined,
                ),
                const Divider(height: 24, thickness: 0.5),
                _buildBreakdownItem(
                  'Sessões (Presenças)',
                  sessions,
                  Colors.teal,
                  Icons.event_available_outlined,
                ),
                if (other > 0) ...[
                  const Divider(height: 24, thickness: 0.5),
                  _buildBreakdownItem(
                    'Outras Entradas',
                    other,
                    Colors.blueGrey,
                    Icons.more_horiz_rounded,
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        Text(
          CurrencyFormatter.formatEuro(value),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
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
            onTap: () =>
                FinancialEntryDialog.show(context, initialType: 'income'),
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
            onTap: () => FinancialEntryDialog.show(context),
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
              onPressed: () => _showAllTransactions(context, financeController),
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

          final displayRecords = financeController.records.take(5).toList();

          return ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayRecords.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final record = displayRecords[index];
              return _buildTransactionItem(context, record);
            },
          );
        }),
      ],
    );
  }

  void _showAllTransactions(
    BuildContext context,
    FinanceController financeController,
  ) {
    final theme = Theme.of(context);
    final periodName = financeController.selectedPeriodType.value == 'daily'
        ? 'Hoje'
        : financeController.selectedPeriodType.value == 'weekly'
        ? 'Esta Semana'
        : financeController.selectedPeriodType.value == 'monthly'
        ? 'Este Mês'
        : 'Personalizado';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Histórico Completo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        periodName,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(127),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),

            // List
            Expanded(
              child: Obx(() {
                if (financeController.records.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma transação encontrada.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  itemCount: financeController.records.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: 54,
                    color: Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (context, index) {
                    final record = financeController.records[index];
                    return _buildTransactionItem(context, record);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, FinancialRecord record) {
    final theme = Theme.of(context);
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
              color: theme.colorScheme.outlineVariant.withAlpha(127),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isIncome ? Colors.green : Colors.red).withAlpha(25),
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
                ],
              ),
            ],
          ),
        ),
      ),
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
              color: Colors.black.withAlpha(25),
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
                              .withAlpha(25),
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
                ],
              ),
              const SizedBox(height: 32),
              _buildDetailRow(
                theme,
                'Valor',
                CurrencyFormatter.formatEuro(record.amount),
                isHighlight: true,
                valueColor: record.type == 'income' ? Colors.green : Colors.red,
              ),
              if (record.description != null &&
                  record.description!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Descrição:',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                      76,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.description!,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
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

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, {
    bool isHighlight = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
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
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(50), width: 1),
            boxShadow: [
              BoxShadow(
                color: Get.theme.colorScheme.shadow.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: color,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              value,
            ],
          ),
        ),
      ),
    );
  }
}
