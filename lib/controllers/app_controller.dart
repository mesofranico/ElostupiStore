import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AppController extends GetxController {
  final GetStorage _storage = GetStorage();
  
  final RxBool autoRefreshEnabled = true.obs;
  final RxBool showResalePrice = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      autoRefreshEnabled.value = _storage.read('auto_refresh_enabled') ?? true;
      showResalePrice.value = _storage.read('show_resale_price') ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar configurações: $e');
      }
    }
  }

  Future<void> toggleAutoRefresh() async {
    autoRefreshEnabled.value = !autoRefreshEnabled.value;
    await _storage.write('auto_refresh_enabled', autoRefreshEnabled.value);
  }

  Future<void> toggleResalePrice() async {
    showResalePrice.value = !showResalePrice.value;
    await _storage.write('show_resale_price', showResalePrice.value);
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