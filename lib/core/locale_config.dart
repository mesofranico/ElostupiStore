import 'package:flutter/material.dart';

class LocaleConfig {
  // Locale padrão para português europeu
  static const Locale defaultLocale = Locale('pt', 'PT');
  
  // Configurações de formatação para português europeu
  static const String currencySymbol = '€';
  static const String decimalSeparator = ',';
  static const String thousandsSeparator = ' ';
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Nomes dos meses em português europeu
  static const List<String> monthNames = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];
  
  // Nomes dos dias da semana em português europeu
  static const List<String> dayNames = [
    'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira',
    'Sexta-feira', 'Sábado', 'Domingo'
  ];
  
  // Nomes abreviados dos dias da semana em português europeu
  static const List<String> shortDayNames = [
    'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'
  ];
  
  // Obter nome do mês
  static String getMonthName(int month) {
    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return '';
  }
  
  // Obter nome do dia da semana
  static String getDayName(int day) {
    if (day >= 1 && day <= 7) {
      return dayNames[day - 1];
    }
    return '';
  }
  
  // Obter nome abreviado do dia da semana
  static String getShortDayName(int day) {
    if (day >= 1 && day <= 7) {
      return shortDayNames[day - 1];
    }
    return '';
  }
  
  // Formatar número com separador de milhares em português europeu
  static String formatNumber(double number) {
    final parts = number.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += thousandsSeparator;
      }
      formattedInteger += integerPart[i];
    }
    
    return '$formattedInteger$decimalSeparator$decimalPart';
  }
  
  // Formatar moeda em português europeu
  static String formatCurrency(double amount) {
    return '$currencySymbol${formatNumber(amount)}';
  }
} 