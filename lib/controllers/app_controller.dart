import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../core/app_style.dart';
import '../core/utils/ui_utils.dart';

class AppController extends GetxController {
  final GetStorage _storage = GetStorage();

  final RxBool showResalePrice = false.obs;
  final RxBool keepScreenOn = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  @override
  void onClose() {
    // Garantir que a tela pode apagar quando o app for fechado
    WakelockPlus.disable();
    super.onClose();
  }

  Future<void> loadSettings() async {
    try {
      showResalePrice.value = _storage.read('show_resale_price') ?? false;
      keepScreenOn.value = _storage.read('keep_screen_on') ?? false;

      // Aplicar configuração de wake lock ao carregar
      if (keepScreenOn.value) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }

      if (kDebugMode) {
        print('Configurações carregadas:');
        print('- Preço de revenda: ${showResalePrice.value}');
        print('- Manter tela ligada: ${keepScreenOn.value}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar configurações: $e');
      }
    }
  }

  Future<void> toggleResalePrice() async {
    showResalePrice.value = !showResalePrice.value;
    await _storage.write('show_resale_price', showResalePrice.value);

    if (kDebugMode) {
      print('Preço de revenda alterado para: ${showResalePrice.value}');
    }

    // Feedback visual
    UiUtils.showSuccess(
      showResalePrice.value
          ? 'Preços de revenda ativados'
          : 'Preços de revenda desativados',
    );
  }

  Future<void> toggleKeepScreenOn() async {
    keepScreenOn.value = !keepScreenOn.value;
    await _storage.write('keep_screen_on', keepScreenOn.value);

    if (keepScreenOn.value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }

    if (kDebugMode) {
      print('Manter tela ligada alterado para: ${keepScreenOn.value}');
    }

    // Feedback visual
    UiUtils.showInfo(
      keepScreenOn.value
          ? 'Tela manterá ligada'
          : 'Tela pode apagar normalmente',
    );
  }

  // Métodos para controle manual do wake lock
  void enableWakeLock() {
    WakelockPlus.enable();
    if (kDebugMode) {
      print('Wake lock ativado');
    }
  }

  void disableWakeLock() {
    WakelockPlus.disable();
    if (kDebugMode) {
      print('Wake lock desativado');
    }
  }

  // Ativar wake lock temporariamente (ex: durante operações importantes)
  void enableWakeLockTemporarily() {
    WakelockPlus.enable();
    // Desativar automaticamente após 5 minutos
    Future.delayed(const Duration(minutes: 5), () {
      if (!keepScreenOn.value) {
        WakelockPlus.disable();
      }
    });
  }

  // Resetar configurações para valores padrão
  Future<void> resetSettings() async {
    try {
      showResalePrice.value = false;
      keepScreenOn.value = false;

      await _storage.write('show_resale_price', false);
      await _storage.write('keep_screen_on', false);

      WakelockPlus.disable();

      if (kDebugMode) {
        print('Configurações resetadas para valores padrão');
      }

      UiUtils.showInfo(
        'Todas as configurações foram restauradas para os valores padrão',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao resetar configurações: $e');
      }
    }
  }

  ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppStyle.primary,
        surface: AppStyle.background,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppStyle.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppStyle.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppStyle.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyle.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppStyle.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
