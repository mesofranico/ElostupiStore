import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/member_controller.dart';
import '../../../controllers/payment_controller.dart';
import '../../../core/currency_formatter.dart';
import '../widgets/membership_shared_widgets.dart';
import '../widgets/membership_dialogs.dart';
import '../membership_utils.dart';
import '../../../core/utils/ui_utils.dart';

class ReportsTab extends StatelessWidget {
  final MemberController memberController;
  final PaymentController paymentController;

  const ReportsTab({
    super.key,
    required this.memberController,
    required this.paymentController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Relatórios de mensalidades',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Análise do sistema de mensalidades',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Indicador de filtro ativo
          Obx(() {
            if (memberController.filterStartDate.value != null &&
                memberController.filterEndDate.value != null) {
              return Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_alt,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filtro: ${MembershipUtils.formatDate(memberController.filterStartDate.value!)} a ${MembershipUtils.formatDate(memberController.filterEndDate.value!)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => memberController.clearDateFilter(),
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 20),

          // Estatísticas em Cards
          Row(
            children: [
              Expanded(
                child: MembershipStatisticCard(
                  title: 'Total de Membros',
                  value: Obx(
                    () => Text(
                      memberController.getFilteredMembers().length.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MembershipStatisticCard(
                  title: 'Membros Ativos',
                  value: Obx(
                    () => Text(
                      memberController
                          .getFilteredMembers()
                          .where((m) => m.isActive)
                          .length
                          .toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: MembershipStatisticCard(
                  title: 'Em Atraso',
                  value: Obx(
                    () => Text(
                      memberController
                          .getFilteredMembers()
                          .where(
                            (m) =>
                                m.paymentStatus == 'overdue' ||
                                (m.nextPaymentDate != null &&
                                    m.nextPaymentDate!.isBefore(
                                      DateTime.now(),
                                    )),
                          )
                          .length
                          .toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MembershipStatisticCard(
                  title: 'Valor Total',
                  value: Obx(
                    () => Text(
                      CurrencyFormatter.formatEuro(
                        paymentController.getFilteredPayments().fold<double>(
                          0,
                          (sum, p) => sum + p.amount,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  icon: Icons.euro,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Relatório Detalhado de Membros
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Análise de membros',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final filteredMembers = memberController.getFilteredMembers();
                  final total = filteredMembers.length;
                  final active = filteredMembers
                      .where((m) => m.isActive)
                      .length;
                  final overdue = filteredMembers
                      .where(
                        (m) =>
                            m.paymentStatus == 'overdue' ||
                            (m.nextPaymentDate != null &&
                                m.nextPaymentDate!.isBefore(DateTime.now())),
                      )
                      .length;
                  final paid = filteredMembers
                      .where((m) => m.paymentStatus == 'paid')
                      .length;

                  return Column(
                    children: [
                      MembershipDetailedReportRow(
                        label: 'Total de Membros',
                        value: total.toString(),
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      MembershipDetailedReportRow(
                        label: 'Membros Ativos',
                        value: active.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      MembershipDetailedReportRow(
                        label: 'Em Atraso',
                        value: overdue.toString(),
                        icon: Icons.warning,
                        color: Colors.red,
                      ),
                      MembershipDetailedReportRow(
                        label: 'Pagamentos em Dia',
                        value: paid.toString(),
                        icon: Icons.payment,
                        color: Colors.green,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Relatório Detalhado de Pagamentos
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.payment, color: Colors.green.shade700, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Análise de pagamentos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final filteredPayments = paymentController
                      .getFilteredPayments();
                  final total = filteredPayments.length;
                  final totalAmount = filteredPayments.fold<double>(
                    0,
                    (sum, p) => sum + p.amount,
                  );
                  final completed = filteredPayments
                      .where((p) => p.status == 'completed')
                      .length;

                  // Calcular estatísticas por tipo
                  final regularPayments = filteredPayments
                      .where((p) => p.paymentType == 'regular')
                      .length;
                  final overduePayments = filteredPayments
                      .where((p) => p.paymentType == 'overdue')
                      .length;
                  final advancePayments = filteredPayments
                      .where((p) => p.paymentType == 'advance')
                      .length;

                  return Column(
                    children: [
                      MembershipDetailedReportRow(
                        label: 'Total de Pagamentos',
                        value: total.toString(),
                        icon: Icons.payment,
                        color: Colors.blue,
                      ),
                      MembershipDetailedReportRow(
                        label: 'Valor Total',
                        value: CurrencyFormatter.formatEuro(totalAmount),
                        icon: Icons.euro,
                        color: Colors.orange,
                      ),
                      MembershipDetailedReportRow(
                        label: 'Concluídos',
                        value: completed.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const Divider(height: 24),
                      MembershipDetailedReportRow(
                        label: 'Pagamentos Regulares',
                        value: regularPayments.toString(),
                        icon: Icons.schedule,
                        color: Colors.blue,
                      ),
                      MembershipDetailedReportRow(
                        label: 'Pagamentos em Atraso',
                        value: overduePayments.toString(),
                        icon: Icons.warning,
                        color: Colors.red,
                      ),
                      MembershipDetailedReportRow(
                        label: 'Pagamentos Antecipados',
                        value: advancePayments.toString(),
                        icon: Icons.trending_up,
                        color: Colors.green,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    UiUtils.showLoadingOverlay(message: 'Gerando relatório...');
                    await Future.delayed(
                      const Duration(milliseconds: 600),
                    ); // Premium feel

                    if (!context.mounted) return;

                    final report = MembershipUtils.generateReportContent(
                      members: memberController.getFilteredMembers(),
                      payments: paymentController.getFilteredPayments(),
                      generationDate: MembershipUtils.formatDate(
                        DateTime.now(),
                      ),
                    );

                    UiUtils.hideLoading();
                    MembershipDialogs.showReportDialog(context, report);
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Exportar relatório'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => MembershipDialogs.showDateRangeDialog(
                    context,
                    memberController,
                  ),
                  icon: const Icon(Icons.date_range, size: 18),
                  label: const Text('Filtrar período'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
