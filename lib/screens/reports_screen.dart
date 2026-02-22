import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/member_controller.dart';
import '../controllers/payment_controller.dart';
import '../widgets/standard_appbar.dart';
import 'membership/tabs/reports_tab.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // If controllers aren't initialized yet (rare, as we added to main.dart),
    // they'll be found via the binding or global puts.
    final MemberController memberController = Get.find<MemberController>();
    final PaymentController paymentController = Get.find<PaymentController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Relatórios Mensais',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: false, // It's a main navigation tab
      ),
      body: ReportsTab(
        memberController: memberController,
        paymentController: paymentController,
      ),
    );
  }
}
