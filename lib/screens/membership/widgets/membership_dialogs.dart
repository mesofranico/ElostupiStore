import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/member_controller.dart';
import '../../../controllers/payment_controller.dart';
import '../../../models/member.dart';
import '../../../models/payment.dart';
import '../../../core/currency_formatter.dart';
import '../../../core/membership_calculator.dart';
import '../../../core/snackbar_helper.dart';
import '../../../core/app_style.dart';
import '../../../core/utils/ui_utils.dart';
import '../membership_utils.dart';
import 'membership_shared_widgets.dart';

class MembershipDialogs {
  static void showAddMemberDialog(
    BuildContext context,
    MemberController controller,
  ) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final feeController = TextEditingController();
    String selectedMembershipType = 'Mensal';
    bool isActive = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors
          .transparent, // Transparente para usar o borderRadius customizado
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle de fecho
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
                            color: AppStyle.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: AppStyle.success,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Novo Membro', style: AppStyle.titleStyle),
                              Text(
                                'Preencha os dados do novo associado',
                                style: AppStyle.subtitleStyle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    Text('Informações Pessoais', style: AppStyle.labelStyle),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone *',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '999 999 999',
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 24),
                    Text('Vínculo Associativo', style: AppStyle.labelStyle),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMembershipType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de mensalidade *',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: ['Mensal', 'Trimestral', 'Semestral', 'Anual']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedMembershipType = value!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: feeController,
                      decoration: const InputDecoration(
                        labelText: 'Valor da mensalidade (€) *',
                        prefixIcon: Icon(Icons.euro_symbol_rounded),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppStyle.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Switch(
                            value: isActive,
                            activeThumbColor: AppStyle.success,
                            onChanged: (value) =>
                                setState(() => isActive = value),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estado Ativo',
                                  style: AppStyle.bodyStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isActive
                                      ? 'Permitir pagamentos'
                                      : 'Suspensão temporária',
                                  style: AppStyle.subtitleStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.trim().isEmpty ||
                                  phoneController.text.trim().isEmpty ||
                                  feeController.text.trim().isEmpty) {
                                SnackBarHelper.showWarning(
                                  context,
                                  'Campos obrigatórios em falta',
                                );
                                return;
                              }

                              final fee = double.tryParse(
                                feeController.text.replaceAll(',', '.'),
                              );
                              if (fee == null || fee <= 0) {
                                SnackBarHelper.showWarning(
                                  context,
                                  'Valor inválido',
                                );
                                return;
                              }

                              try {
                                final newMember = Member(
                                  name: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  membershipType: selectedMembershipType,
                                  monthlyFee: fee,
                                  joinDate: DateTime.now(),
                                  isActive: isActive,
                                  paymentStatus: 'pending',
                                  nextPaymentDate:
                                      MembershipCalculator.calculateFirstPaymentDate(
                                        DateTime.now(),
                                      ),
                                );

                                final success = await controller.createMember(
                                  newMember,
                                );
                                if (!sheetContext.mounted) return;

                                if (success) {
                                  Navigator.of(sheetContext).pop();
                                  await controller.loadMembers();
                                  if (context.mounted) {
                                    SnackBarHelper.showSuccess(
                                      context,
                                      'Membro adicionado!',
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    SnackBarHelper.showError(
                                      context,
                                      controller.errorMessage.value,
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  SnackBarHelper.showError(
                                    context,
                                    'Erro inesperado: $e',
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyle.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Confirmar Subscrição'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static void showEditMemberDialog(
    BuildContext context,
    Member member,
    MemberController controller,
  ) {
    final nameController = TextEditingController(text: member.name);
    final emailController = TextEditingController(text: member.email);
    final phoneController = TextEditingController(text: member.phone);
    final feeController = TextEditingController(
      text: member.monthlyFee.toString(),
    );
    String selectedMembershipType = member.membershipType;
    bool isActive = member.isActive;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              final isOverdue =
                  member.overdueMonths != null && member.overdueMonths! > 0;

              return SingleChildScrollView(
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
                            color: AppStyle.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: AppStyle.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Editar Membro', style: AppStyle.titleStyle),
                              Text(member.name, style: AppStyle.subtitleStyle),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    Text('Informações Pessoais', style: AppStyle.labelStyle),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 24),
                    Text('Vínculo Associativo', style: AppStyle.labelStyle),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedMembershipType,
                      decoration: InputDecoration(
                        labelText: 'Tipo de mensalidade *',
                        prefixIcon: const Icon(Icons.category_outlined),
                        suffixIcon: isOverdue
                            ? const Tooltip(
                                message: 'Atrasos impedem troca de tipo',
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppStyle.accent,
                                ),
                              )
                            : null,
                      ),
                      items: ['Mensal', 'Trimestral', 'Semestral', 'Anual']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: isOverdue
                          ? null
                          : (value) =>
                                setState(() => selectedMembershipType = value!),
                    ),
                    if (isOverdue)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          'Pague os atrasos para habilitar a troca de plano.',
                          style: TextStyle(
                            color: AppStyle.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: feeController,
                      decoration: const InputDecoration(
                        labelText: 'Valor da mensalidade (€) *',
                        prefixIcon: Icon(Icons.euro_symbol_rounded),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppStyle.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Switch(
                                value: isActive,
                                activeThumbColor: AppStyle.success,
                                onChanged: (value) =>
                                    setState(() => isActive = value),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estado Ativo',
                                      style: AppStyle.bodyStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      isActive
                                          ? 'Vínculo ativo'
                                          : 'Vínculo suspenso',
                                      style: AppStyle.subtitleStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.trim().isEmpty ||
                                  feeController.text.trim().isEmpty) {
                                return;
                              }
                              final fee = double.tryParse(
                                feeController.text.replaceAll(',', '.'),
                              );
                              if (fee == null || fee <= 0) return;

                              try {
                                final updatedMember = member.copyWith(
                                  name: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  membershipType: selectedMembershipType,
                                  monthlyFee: fee,
                                  isActive: isActive,
                                );
                                final success = await controller.updateMember(
                                  updatedMember,
                                );
                                if (!sheetContext.mounted) return;
                                if (success) {
                                  Navigator.of(sheetContext).pop();
                                  await controller.loadMembers();
                                }
                              } catch (_) {}
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyle.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Guardar Alterações'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static void showPaymentDialog(BuildContext context, Member member) {
    final paymentController = Get.find<PaymentController>();
    final memberController = Get.find<MemberController>();

    if (!member.isActive) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(
                Icons.person_off_rounded,
                color: AppStyle.danger,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text('Membro Inativo', style: AppStyle.titleStyle),
              const SizedBox(height: 8),
              Text(
                'Associados inativos não podem realizar pagamentos. Ative a conta primeiro.',
                style: AppStyle.subtitleStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyle.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Estado do diálogo
    final overdueMonths = member.overdueMonths ?? 0;
    final overdueAmount = member.totalOverdue ?? 0;

    String paymentType = overdueMonths > 0 ? 'overdue' : 'regular';
    int numberOfMonths = 1;
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              // Calcular total amout dinamicamente
              double currentTotal = 0;
              if (paymentType == 'overdue') {
                currentTotal = overdueAmount;
              } else if (paymentType == 'regular') {
                currentTotal = member.monthlyFee;
              } else {
                currentTotal = MembershipUtils.calculateTotalAmount(
                  member.membershipType,
                  member.monthlyFee,
                  numberOfMonths,
                );
              }

              return SingleChildScrollView(
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
                            color: AppStyle.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppStyle.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registar Pagamento',
                                style: AppStyle.titleStyle,
                              ),
                              Text(member.name, style: AppStyle.subtitleStyle),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppStyle.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _paymentOption(
                            title: 'Mensalidades em Atraso',
                            subtitle: '$overdueMonths meses acumulados',
                            value: 'overdue',
                            groupValue: paymentType,
                            visible: overdueMonths > 0,
                            amount: overdueAmount,
                            onChanged: (v) => setState(() => paymentType = v!),
                          ),
                          _paymentOption(
                            title: 'Mensalidade Regular',
                            subtitle: 'Período atual',
                            value: 'regular',
                            groupValue: paymentType,
                            visible: overdueMonths == 0,
                            amount: member.monthlyFee,
                            onChanged: (v) => setState(() => paymentType = v!),
                          ),
                          _paymentOption(
                            title: 'Pagamento Antecipado',
                            subtitle: 'Pagar múltiplos meses',
                            value: 'advance',
                            groupValue: paymentType,
                            visible: overdueMonths == 0,
                            amount: MembershipUtils.calculateTotalAmount(
                              member.membershipType,
                              member.monthlyFee,
                              numberOfMonths,
                            ),
                            onChanged: (v) => setState(() => paymentType = v!),
                          ),
                        ],
                      ),
                    ),

                    if (paymentType == 'advance') ...[
                      const SizedBox(height: 24),
                      Text('Selecionar Período', style: AppStyle.labelStyle),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              MembershipUtils.getAdvanceOptions(
                                member.membershipType,
                              ).map((opt) {
                                final m = opt['months'] as int;
                                final selected = numberOfMonths == m;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(opt['label'] as String),
                                    selected: selected,
                                    onSelected: (val) =>
                                        setState(() => numberOfMonths = m),
                                    selectedColor: AppStyle.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? AppStyle.primary
                                          : AppStyle.secondary,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppStyle.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppStyle.mediumShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total a Receber',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatEuro(currentTotal),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setState(() => isProcessing = true);
                              try {
                                int monthsToAdvance = 1;
                                if (paymentType == 'overdue') {
                                  monthsToAdvance = overdueMonths;
                                } else if (paymentType == 'advance') {
                                  monthsToAdvance = numberOfMonths;
                                }

                                final payment = Payment(
                                  memberId: member.id!,
                                  amount: currentTotal,
                                  paymentDate: DateTime.now(),
                                  status: 'completed',
                                  paymentType: paymentType,
                                  createdAt: DateTime.now(),
                                );

                                final success = await paymentController
                                    .createPayment(
                                      payment,
                                      showSnackbar: false,
                                      showLoading: false,
                                    );

                                if (!success) {
                                  setState(() => isProcessing = false);
                                  if (context.mounted) {
                                    SnackBarHelper.showError(
                                      context,
                                      'Erro ao registar pagamento',
                                    );
                                  }
                                  return;
                                }

                                // Lógica de atualização de datas
                                DateTime nextDate;
                                final base =
                                    member.nextPaymentDate ?? DateTime.now();

                                if (paymentType == 'overdue') {
                                  nextDate =
                                      MembershipCalculator.calculateNextPaymentAfterOverdue(
                                        member.lastPaymentDate ??
                                            member.joinDate,
                                        member.membershipType,
                                        monthsToAdvance,
                                      );
                                } else {
                                  nextDate = base;
                                  for (int i = 0; i < monthsToAdvance; i++) {
                                    nextDate =
                                        MembershipCalculator.calculateNextPaymentByType(
                                          member.membershipType,
                                          fromDate: nextDate,
                                        );
                                  }
                                }

                                await memberController.updateMember(
                                  member.copyWith(
                                    lastPaymentDate: DateTime.now(),
                                    nextPaymentDate: nextDate,
                                    paymentStatus: 'paid',
                                  ),
                                  showSnackbar: false,
                                  showLoading: false,
                                );

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                  memberController.loadMembers(
                                    showLoading: false,
                                  );

                                  // Mostrar snackbar após o fecho do bottomsheet.
                                  // Usamos um atraso ligeiramente maior e removemos context.mounted se necessário,
                                  // ou garantimos que usamos o contexto global do GetX se UiUtils o permitir.
                                  Future.delayed(
                                    const Duration(milliseconds: 500),
                                    () {
                                      UiUtils.showSuccess(
                                        'Pagamento de "${member.name}" efectuado com sucesso!',
                                      );
                                    },
                                  );
                                }
                              } catch (e) {
                                setState(() => isProcessing = false);
                                if (context.mounted) {
                                  UiUtils.showError('Erro inesperado: $e');
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyle.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: AppStyle.primary.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirmar Pagamento',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static Widget _paymentOption({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required bool visible,
    required double amount,
    required ValueChanged<String?> onChanged,
  }) {
    if (!visible) return const SizedBox.shrink();
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppStyle.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? AppStyle.softShadow : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppStyle.primary : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppStyle.primary : Colors.black87,
                    ),
                  ),
                  Text(subtitle, style: AppStyle.subtitleStyle),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.formatEuro(amount),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppStyle.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showDeleteConfirmation(
    BuildContext context,
    Member member,
    MemberController controller,
  ) {
    final PaymentController paymentController = Get.find<PaymentController>();
    final memberPayments = paymentController.payments
        .where((p) => p.memberId == member.id)
        .toList();
    final totalPayments = memberPayments.length;
    final totalAmount = memberPayments.fold<double>(
      0,
      (sum, p) => sum + p.amount,
    );
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: theme.colorScheme.error,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confirmar exclusão',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Esta ação não pode ser desfeita',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Tens a certeza que queres excluir o membro:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
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
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        member.name[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            MembershipUtils.capitalizeFirstLetter(
                              member.membershipType,
                            ),
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.delete_forever,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dados que serão removidos:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MembershipInfoRow(
                      icon: Icons.person,
                      label: 'Perfil do membro',
                      value: 'Completamente removido',
                      valueColor: theme.colorScheme.error,
                    ),
                    MembershipInfoRow(
                      icon: Icons.payment,
                      label: 'Histórico de pagamentos',
                      value: '$totalPayments pagamento(s)',
                      valueColor: theme.colorScheme.error,
                    ),
                    MembershipInfoRow(
                      icon: Icons.euro,
                      label: 'Valor total em pagamentos',
                      value: CurrencyFormatter.formatEuro(totalAmount),
                      valueColor: theme.colorScheme.error,
                    ),
                    MembershipInfoRow(
                      icon: Icons.schedule,
                      label: 'Datas e status',
                      value: 'Todas as informações temporais',
                      valueColor: theme.colorScheme.error,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta ação é irreversível. Todos os dados do membro serão removidos permanentemente.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        try {
                          final success = await controller.deleteMember(
                            member.id!,
                          );
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                          if (success) {
                            await controller.loadMembers();
                            if (context.mounted) {
                              SnackBarHelper.showSuccess(
                                context,
                                'Membro "${member.name}" foi excluído com sucesso',
                              );
                            }
                          } else {
                            if (context.mounted) {
                              SnackBarHelper.showError(
                                context,
                                controller.errorMessage.value.isNotEmpty
                                    ? controller.errorMessage.value
                                    : 'Erro ao excluir membro. Tenta novamente.',
                              );
                            }
                          }
                        } catch (e) {
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                          if (context.mounted) {
                            SnackBarHelper.showError(
                              context,
                              'Erro inesperado ao excluir membro: $e',
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Confirmar exclusão'),
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

  static void showMemberDetails(BuildContext context, Member member) {
    final isOverdue = member.overdueMonths != null && member.overdueMonths! > 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppStyle.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: isOverdue
                          ? AppStyle.dangerGradient
                          : AppStyle.successGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppStyle.softShadow,
                    ),
                    child: Center(
                      child: Text(
                        member.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name, style: AppStyle.titleStyle),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isOverdue ? AppStyle.danger : AppStyle.success)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            MembershipUtils.capitalizeFirstLetter(
                              member.membershipType,
                            ),
                            style: AppStyle.labelStyle.copyWith(
                              color: isOverdue
                                  ? AppStyle.danger
                                  : AppStyle.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppStyle.cardDecoration(
                        color: member.isActive
                            ? AppStyle.success.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.05),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            member.isActive ? Icons.check_circle : Icons.cancel,
                            color: member.isActive
                                ? AppStyle.success
                                : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Membro ${member.isActive ? 'Ativo' : 'Inativo'}',
                            style: AppStyle.titleStyle.copyWith(
                              fontSize: 16,
                              color: member.isActive
                                  ? AppStyle.success
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact Info
                    _buildDetailSection(
                      title: 'Informações de Contato',
                      children: [
                        _buildDetailRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: member.email?.isNotEmpty == true
                              ? member.email!
                              : 'Não informado',
                        ),
                        _buildDetailRow(
                          icon: Icons.phone_outlined,
                          label: 'Telefone',
                          value: member.phone.isNotEmpty
                              ? member.phone
                              : 'Não informado',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Financial Info
                    _buildDetailSection(
                      title: 'Informações Financeiras',
                      children: [
                        _buildDetailRow(
                          icon: Icons.euro_outlined,
                          label: 'Valor Mensal',
                          value: CurrencyFormatter.formatEuro(
                            member.monthlyFee,
                          ),
                          valueColor: AppStyle.primary,
                        ),
                        _buildDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Data de Ingresso',
                          value: MembershipUtils.formatDate(member.joinDate),
                        ),
                        if (member.lastPaymentDate != null)
                          _buildDetailRow(
                            icon: Icons.history_outlined,
                            label: 'Último Pagamento',
                            value: MembershipUtils.formatDate(
                              member.lastPaymentDate!,
                            ),
                          ),
                        if (member.nextPaymentDate != null)
                          _buildDetailRow(
                            icon: isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.schedule_outlined,
                            label: 'Próximo Pagamento',
                            value: MembershipUtils.formatDate(
                              member.nextPaymentDate!,
                            ),
                            valueColor: isOverdue
                                ? AppStyle.danger
                                : AppStyle.success,
                          ),
                      ],
                    ),

                    if (isOverdue) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppStyle.danger.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppStyle.danger.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_rounded,
                                  color: AppStyle.danger,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Pagamento em Atraso',
                                  style: AppStyle.titleStyle.copyWith(
                                    fontSize: 18,
                                    color: AppStyle.danger,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              icon: Icons.timer_outlined,
                              label: 'Tempo de atraso',
                              value:
                                  '${member.overdueMonths! * 30} dias (${member.overdueMonths} mês/meses)',
                              valueColor: AppStyle.danger,
                            ),
                            _buildDetailRow(
                              icon: Icons.payments_outlined,
                              label: 'Total em dívida',
                              value: CurrencyFormatter.formatEuro(
                                member.totalOverdue ?? 0,
                              ),
                              valueColor: AppStyle.danger,
                              isImportant: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDetailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppStyle.labelStyle),
        const SizedBox(height: 12),
        Container(
          decoration: AppStyle.cardDecoration(showShadow: false),
          child: Column(children: children),
        ),
      ],
    );
  }

  static Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isImportant = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppStyle.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppStyle.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppStyle.subtitleStyle.copyWith(fontSize: 12),
                ),
                Text(
                  value,
                  style: isImportant
                      ? AppStyle.titleStyle.copyWith(
                          fontSize: 16,
                          color: valueColor,
                        )
                      : AppStyle.bodyStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: valueColor,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void showPaymentDetails(BuildContext context, Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppStyle.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: MembershipUtils.getPaymentStatusColor(
                        payment.status,
                      ).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      MembershipUtils.getPaymentStatusIcon(payment.status),
                      color: MembershipUtils.getPaymentStatusColor(
                        payment.status,
                      ),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recibo de Pagamento', style: AppStyle.titleStyle),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: MembershipUtils.getPaymentStatusColor(
                                  payment.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                MembershipUtils.getPaymentStatusText(
                                  payment.status,
                                ).toUpperCase(),
                                style: AppStyle.labelStyle.copyWith(
                                  color: MembershipUtils.getPaymentStatusColor(
                                    payment.status,
                                  ),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildDetailSection(
                      title: 'Detalhes da Transação',
                      children: [
                        _buildDetailRow(
                          icon: Icons.person_outline,
                          label: 'Membro',
                          value: payment.memberName ?? 'Não informado',
                        ),
                        _buildDetailRow(
                          icon: Icons.euro_outlined,
                          label: 'Valor Pago',
                          value: CurrencyFormatter.formatEuro(payment.amount),
                          valueColor: AppStyle.primary,
                          isImportant: true,
                        ),
                        _buildDetailRow(
                          icon: Icons.category_outlined,
                          label: 'Tipo de Pagamento',
                          value: MembershipUtils.getPaymentTypeText(
                            payment.paymentType,
                          ),
                        ),
                        _buildDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Data do Pagamento',
                          value: MembershipUtils.formatDate(
                            payment.paymentDate,
                          ),
                        ),
                        _buildDetailRow(
                          icon: Icons.history_toggle_off,
                          label: 'Registado em',
                          value: MembershipUtils.formatDate(payment.createdAt),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement receipt printing
                        },
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Imprimir Recibo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyle.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showReportDialog(BuildContext context, String reportContent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppStyle.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppStyle.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppStyle.success,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Relatório de Gestão', style: AppStyle.titleStyle),
                        Text(
                          'Análise detalhada do período',
                          style: AppStyle.subtitleStyle,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: AppStyle.softShadow,
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      reportContent,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement copy
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copiar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement share
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Partilhar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyle.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showDateRangeDialog(
    BuildContext context,
    MemberController controller,
  ) {
    DateTime? startDate = controller.filterStartDate.value;
    DateTime? endDate = controller.filterEndDate.value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppStyle.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppStyle.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.date_range_rounded,
                        color: AppStyle.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Filtrar Período', style: AppStyle.titleStyle),
                          Text(
                            'Selecione as datas para o relatório',
                            style: AppStyle.subtitleStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Date Pickers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildDateSelector(
                      context,
                      label: 'De',
                      date: startDate,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              startDate ??
                              DateTime.now().subtract(const Duration(days: 30)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => startDate = date);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDateSelector(
                      context,
                      label: 'Até',
                      date: endDate,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => endDate = date);
                      },
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: startDate != null && endDate != null
                            ? () {
                                controller.applyDateFilter(
                                  startDate!,
                                  endDate!,
                                );
                                Navigator.pop(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyle.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Aplicar Filtro'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDateSelector(
    BuildContext context, {
    required String label,
    DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppStyle.labelStyle.copyWith(fontSize: 10)),
                const SizedBox(height: 4),
                Text(
                  date != null
                      ? MembershipUtils.formatDate(date)
                      : 'Selecionar data',
                  style: AppStyle.bodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: date != null ? AppStyle.primary : Colors.grey,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.calendar_today_rounded,
              color: AppStyle.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
