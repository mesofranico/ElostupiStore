import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/member_controller.dart';
import '../controllers/payment_controller.dart';
import '../controllers/finance_controller.dart';
import '../widgets/standard_appbar.dart';
import '../services/finance_report_service.dart';
import 'membership/tabs/reports_tab.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // If controllers aren't initialized yet (rare, as we added to main.dart),
    // they'll be found via the binding or global puts.
    final MemberController memberController = Get.find<MemberController>();
    final PaymentController paymentController = Get.find<PaymentController>();
    final FinanceController financeController = Get.find<FinanceController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Relatórios Mensais',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: false, // It's a main navigation tab
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Imprimir Relatório',
            onPressed: () => FinanceReportService.generateAndPrintReport(
              title: 'Relatório Financeiro',
              startDate: financeController.startDate.value,
              endDate: financeController.endDate.value,
              totalIncome: financeController.totalIncome,
              totalExpense: financeController.totalExpense,
              incomeBreakdown: financeController.consolidatedReport['income'] ?? {},
              records: financeController.records,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ReportsTab(
        memberController: memberController,
        paymentController: paymentController,
      ),
    );
  }
}
