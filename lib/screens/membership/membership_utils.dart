import 'package:flutter/material.dart';
import '../../../core/currency_formatter.dart';

class MembershipUtils {
  static String formatDate(DateTime date) {
    return CurrencyFormatter.formatDate(date);
  }

  static String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static double calculateTotalAmount(
    String membershipType,
    double monthlyFee,
    int numberOfPeriods,
  ) {
    return monthlyFee * numberOfPeriods;
  }

  static List<Map<String, dynamic>> getAdvanceOptions(String membershipType) {
    switch (membershipType.toLowerCase()) {
      case 'mensal':
        return [
          {'months': 1, 'label': '1 Mês'},
          {'months': 2, 'label': '2 Meses'},
          {'months': 3, 'label': '3 Meses'},
        ];
      case 'trimestral':
        return [
          {'months': 1, 'label': '1 Trimestre'},
          {'months': 2, 'label': '2 Trimestres'},
          {'months': 3, 'label': '3 Trimestres'},
        ];
      case 'semestral':
        return [
          {'months': 1, 'label': '1 Semestre'},
          {'months': 2, 'label': '2 Semestres'},
        ];
      case 'anual':
        return [
          {'months': 1, 'label': '1 Ano'},
          {'months': 2, 'label': '2 Anos'},
        ];
      default:
        return [
          {'months': 1, 'label': '1 Período'},
          {'months': 2, 'label': '2 Períodos'},
          {'months': 3, 'label': '3 Períodos'},
        ];
    }
  }

  // Helpers for payment status
  static Color getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  static String getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Concluído';
      case 'pending':
        return 'Pendente';
      case 'failed':
        return 'Falhado';
      default:
        return 'Desconhecido';
    }
  }

  static Color getPaymentTypeColor(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'regular':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      case 'advance':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static String getPaymentTypeText(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'regular':
        return 'Mensal';
      case 'overdue':
        return 'Em Atraso';
      case 'advance':
        return 'Adiantado';
      default:
        return 'Regular';
    }
  }

  static String generateReportContent({
    required List<dynamic> members,
    required List<dynamic> payments,
    required String generationDate,
  }) {
    // Estatísticas gerais
    final totalMembers = members.length;
    final activeMembers = members.where((m) => m.isActive).length;
    final overdueMembers = members
        .where(
          (m) =>
              m.paymentStatus == 'overdue' ||
              (m.nextPaymentDate != null &&
                  m.nextPaymentDate!.isBefore(DateTime.now())),
        )
        .length;
    final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amount);

    // Estatísticas por tipo de pagamento
    final regularPayments = payments
        .where((p) => p.paymentType == 'regular')
        .length;
    final overduePayments = payments
        .where((p) => p.paymentType == 'overdue')
        .length;
    final advancePayments = payments
        .where((p) => p.paymentType == 'advance')
        .length;

    // Membros em atraso detalhados
    final overdueMembersList = members
        .where(
          (m) =>
              m.paymentStatus == 'overdue' ||
              (m.nextPaymentDate != null &&
                  m.nextPaymentDate!.isBefore(DateTime.now())),
        )
        .toList();

    // Últimos pagamentos
    final recentPayments = payments.take(10).toList();

    StringBuffer report = StringBuffer();

    // Cabeçalho do relatório
    report.writeln('=' * 60);
    report.writeln('RELATÓRIO DE MENSUALIDADES - ELOSTUPI STORE');
    report.writeln('=' * 60);
    report.writeln('Data de geração: $generationDate');
    report.writeln('');

    // Resumo executivo
    report.writeln('RESUMO EXECUTIVO');
    report.writeln('-' * 30);
    report.writeln('Total de Membros: $totalMembers');
    report.writeln('Membros Ativos: $activeMembers');
    report.writeln('Membros em Atraso: $overdueMembers');
    report.writeln(
      'Valor Total em Pagamentos: ${CurrencyFormatter.formatEuro(totalAmount)}',
    );
    report.writeln('');

    // Estatísticas de pagamentos
    report.writeln('ESTATÍSTICAS DE PAGAMENTOS');
    report.writeln('-' * 30);
    report.writeln('Total de Pagamentos: ${payments.length}');
    report.writeln('Pagamentos Regulares: $regularPayments');
    report.writeln('Pagamentos em Atraso: $overduePayments');
    report.writeln('Pagamentos Antecipados: $advancePayments');
    report.writeln('');

    // Membros em atraso
    if (overdueMembersList.isNotEmpty) {
      report.writeln('MEMBROS EM ATRASO');
      report.writeln('-' * 30);
      for (var member in overdueMembersList) {
        final daysOverdue = member.nextPaymentDate != null
            ? DateTime.now().difference(member.nextPaymentDate!).inDays
            : 0;
        report.writeln(
          '• ${member.name} - ${member.overdueMonths ?? 0} mensalidades - $daysOverdue dias',
        );
      }
      report.writeln('');
    }

    // Últimos pagamentos
    if (recentPayments.isNotEmpty) {
      report.writeln('ÚLTIMOS PAGAMENTOS');
      report.writeln('-' * 30);
      for (var payment in recentPayments) {
        final paymentType = getPaymentTypeText(payment.paymentType);
        report.writeln(
          '• ${payment.memberName ?? 'Membro não encontrado'} - ${CurrencyFormatter.formatEuro(payment.amount)} - $paymentType - ${formatDate(payment.paymentDate)}',
        );
      }
      report.writeln('');
    }

    // Rodapé
    report.writeln('=' * 60);
    report.writeln('Relatório gerado automaticamente pelo sistema');
    report.writeln('Elostupi Store - Gestão de Mensalidades');
    report.writeln('=' * 60);

    return report.toString();
  }
}
