import 'package:flutter/material.dart';
import 'utils/ui_utils.dart';

class SnackBarHelper {
  /// Mostra um SnackBar de sucesso usando o estilo premium do UiUtils
  static void showSuccess(BuildContext context, String message) {
    UiUtils.showSuccess(message);
  }

  /// Mostra um SnackBar de erro usando o estilo premium do UiUtils
  static void showError(BuildContext context, String message) {
    UiUtils.showError(message);
  }

  /// Mostra um SnackBar de aviso usando o estilo premium do UiUtils
  static void showWarning(BuildContext context, String message) {
    UiUtils.showWarning(message);
  }

  /// Mostra um SnackBar de informação usando o estilo premium do UiUtils
  static void showInfo(BuildContext context, String message) {
    UiUtils.showInfo(message);
  }

  /// Mostra um SnackBar personalizado mapeado para o estilo premium
  static void showCustom(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
    EdgeInsets? margin,
  }) {
    // Para custom o ideal é usar o showPremiumSnackbar diretamente
    UiUtils.showPremiumSnackbar(
      title: 'Aviso',
      message: message,
      icon: icon,
      color: backgroundColor,
      duration: duration,
    );
  }
}
