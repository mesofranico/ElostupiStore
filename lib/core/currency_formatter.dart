class CurrencyFormatter {
  // Formatar valor em Euro
  static String formatEuro(double value) {
    return '€${value.toStringAsFixed(2)}';
  }

  // Formatar valor em Euro com separador de milhares em português europeu
  static String formatEuroWithSeparator(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    // Adicionar separador de milhares (espaço em português europeu)
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += ' ';
      }
      formattedInteger += integerPart[i];
    }
    
    return '€$formattedInteger,$decimalPart';
  }

  // Formatar data em português europeu (dd/MM/yyyy)
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Formatar data e hora em português europeu
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Obter nome do mês em português europeu
  static String getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }

  // Formatar mês e ano em português europeu
  static String formatMonthYear(DateTime date) {
    return '${getMonthName(date.month)} ${date.year}';
  }
} 