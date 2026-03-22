import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/member_controller.dart';
import '../controllers/payment_controller.dart';
import '../widgets/standard_appbar.dart';
import 'membership/tabs/members_tab.dart';
import 'membership/tabs/payments_tab.dart';
import 'membership/widgets/membership_dialogs.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final MemberController memberController = Get.find<MemberController>();
  final PaymentController paymentController = Get.find<PaymentController>();

  @override
  void initState() {
    super.initState();
    // Atualizar dados ao entrar no ecrã
    WidgetsBinding.instance.addPostFrameCallback((_) {
      memberController.loadMembers(showLoading: false);
      paymentController.loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: StandardAppBar(
          title: 'Gestão de mensalidades',
          backgroundColor: theme.colorScheme.primary,
          showBackButton: true,
          bottom: TabBar(
            indicatorColor: theme.colorScheme.onPrimary,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onPrimary.withValues(
              alpha: 0.8,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'Membros'),
              Tab(icon: Icon(Icons.payment), text: 'Pagamentos'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: FilledButton.icon(
                onPressed: () => MembershipDialogs.showAddMemberDialog(
                  context,
                  memberController,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Novo membro'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.primary,
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            MembersTab(controller: memberController),
            PaymentsTab(controller: paymentController),
          ],
        ),
      ),
    );
  }
}
