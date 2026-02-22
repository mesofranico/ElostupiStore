import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app_style.dart';

class UiUtils {
  // Custom Modern Snackbar
  static void showPremiumSnackbar({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color.withValues(alpha: 0.9),
      colorText: Colors.white,
      icon: Icon(icon, color: Colors.white),
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      boxShadows: AppStyle.softShadow,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  static void showSuccess(String message) {
    showPremiumSnackbar(
      title: 'Sucesso',
      message: message,
      icon: Icons.check_circle_outline,
      color: AppStyle.success,
    );
  }

  static void showError(String message) {
    showPremiumSnackbar(
      title: 'Erro',
      message: message,
      icon: Icons.error_outline,
      color: AppStyle.danger,
    );
  }

  static void showInfo(String message) {
    showPremiumSnackbar(
      title: 'Informação',
      message: message,
      icon: Icons.info_outline,
      color: AppStyle.primary,
    );
  }

  // Modern Loading Indicator
  static void showLoadingOverlay({String? message}) {
    Get.dialog(
      Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: AppStyle.glassDecoration(
            color: Colors.white,
            opacity: 0.8,
            blur: 15,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppStyle.primary),
                strokeWidth: 3,
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: AppStyle.labelStyle.copyWith(
                    color: AppStyle.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.1),
    );
  }

  static void hideLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // Transition Helpers
  static Widget animatedFadeIn(Widget child, {int delayMs = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
