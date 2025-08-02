import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
    Get.snackbar(
      'Configuração Atualizada',
      showResalePrice.value 
        ? 'Preços de revenda ativados' 
        : 'Preços de revenda desativados',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
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
    Get.snackbar(
      'Configuração Atualizada',
      keepScreenOn.value 
        ? 'Tela manterá ligada' 
        : 'Tela pode apagar normalmente',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
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
      
      Get.snackbar(
        'Configurações Resetadas',
        'Todas as configurações foram restauradas para os valores padrão',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao resetar configurações: $e');
      }
    }
  }

  ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
} 