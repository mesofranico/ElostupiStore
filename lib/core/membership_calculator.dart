class MembershipCalculator {
  /// Calcula quantas mensalidades estão em atraso
  static int calculateOverdueMonths(DateTime joinDate, DateTime? lastPaymentDate, String membershipType) {
    final now = DateTime.now();
    
    // Se não há último pagamento, calcular desde o primeiro dia do mês seguinte ao ingresso
    DateTime startDate;
    if (lastPaymentDate != null) {
      startDate = lastPaymentDate;
    } else {
      // Primeira mensalidade sempre no dia 1 do mês seguinte ao ingresso
      int nextMonth = joinDate.month + 1;
      int nextYear = joinDate.year;
      
      // Se passou de dezembro, ajustar para janeiro do ano seguinte
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      
      startDate = DateTime(nextYear, nextMonth, 1);
    }
    
    // Calcular quantos períodos deveriam ter sido pagos
    int expectedPayments = 0;
    DateTime currentDate = startDate;
    
    while (currentDate.isBefore(now)) {
      expectedPayments++;
      currentDate = _addPeriod(currentDate, membershipType);
    }
    
    return expectedPayments;
  }
  
  /// Calcula o valor total em atraso
  static double calculateTotalOverdue(double monthlyFee, int overdueMonths) {
    return monthlyFee * overdueMonths;
  }
  
  /// Calcula a próxima data de pagamento após pagar todas as mensalidades em atraso
  static DateTime calculateNextPaymentAfterOverdue(DateTime? lastPaymentDate, String membershipType, int paidMonths) {
    DateTime baseDate;
    
    if (lastPaymentDate != null) {
      baseDate = lastPaymentDate;
    } else {
      // Se não há último pagamento, usar o primeiro dia do mês atual
      final now = DateTime.now();
      baseDate = DateTime(now.year, now.month, 1);
    }
    
    DateTime nextDate = baseDate;
    
    // Adicionar os períodos pagos
    for (int i = 0; i < paidMonths; i++) {
      nextDate = _addPeriod(nextDate, membershipType);
    }
    
    // Garantir que a data final seja sempre no dia 1 do mês
    return DateTime(nextDate.year, nextDate.month, 1);
  }
  
  /// Adiciona um período baseado no tipo de mensalidade
  static DateTime _addPeriod(DateTime date, String membershipType) {
    DateTime nextDate;
    
    switch (membershipType.toLowerCase()) {
      case 'mensal':
        nextDate = DateTime(date.year, date.month + 1, date.day);
        break;
      case 'trimestral':
        nextDate = DateTime(date.year, date.month + 3, date.day);
        break;
      case 'semestral':
        nextDate = DateTime(date.year, date.month + 6, date.day);
        break;
      case 'anual':
        nextDate = DateTime(date.year + 1, date.month, date.day);
        break;
      default:
        nextDate = DateTime(date.year, date.month + 1, date.day);
    }
    
    // Sempre retornar o dia 1 do mês
    return DateTime(nextDate.year, nextDate.month, 1);
  }
  
  /// Calcula a primeira data de pagamento (sempre dia 1 do mês seguinte ao ingresso)
  static DateTime calculateFirstPaymentDate(DateTime joinDate) {
    // Calcular o mês seguinte, lidando com a mudança de ano
    int nextMonth = joinDate.month + 1;
    int nextYear = joinDate.year;
    
    // Se passou de dezembro, ajustar para janeiro do ano seguinte
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    
    return DateTime(nextYear, nextMonth, 1);
  }
  
  /// Verifica se um membro está em atraso
  static bool isOverdue(DateTime? nextPaymentDate) {
    if (nextPaymentDate == null) return false;
    return nextPaymentDate.isBefore(DateTime.now());
  }
  
  /// Calcula dias em atraso
  static int calculateDaysOverdue(DateTime? nextPaymentDate) {
    if (nextPaymentDate == null) return 0;
    final now = DateTime.now();
    return now.difference(nextPaymentDate).inDays;
  }

  /// Calcula a próxima data de pagamento para pagamentos regulares (sem atraso)
  static DateTime calculateNextRegularPayment(DateTime currentPaymentDate, String membershipType) {
    // Calcular baseado na data do pagamento atual
    DateTime nextDate = _addPeriod(currentPaymentDate, membershipType);
    
    // Garantir que a data final seja sempre no dia 1 do mês
    return DateTime(nextDate.year, nextDate.month, 1);
  }

  /// Calcula a próxima data de pagamento baseada no tipo de mensalidade
  static DateTime calculateNextPaymentByType(String membershipType, {DateTime? fromDate}) {
    final baseDate = fromDate ?? DateTime.now();
    
    // Usar a função _addPeriod que já lida corretamente com mudança de ano
    return _addPeriod(baseDate, membershipType);
  }
} 