import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'core/storage_init.dart';
import 'core/locale_config.dart';
import 'controllers/app_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/consulente_controller.dart';
import 'controllers/attendance_controller.dart';
import 'services/bluetooth_print_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/admin_products_screen.dart';
import 'screens/membership_screen.dart';
import 'screens/electricity_reading_screen.dart';
import 'screens/electricity_settings_screen.dart';
import 'screens/bluetooth_printer_screen.dart';
import 'screens/consulentes_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/recados_screen.dart';
import 'controllers/recado_controller.dart';
import 'screens/membership/membership_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageInit.init();

  // Inicializar controllers na ordem correta
  Get.put(AppController());
  Get.put(BluetoothPrintService()); // Serviço Bluetooth primeiro
  Get.put(CartController()); // CartController primeiro
  Get.put(ProductController()); // ProductController depois
  Get.put(ConsulentesController()); // ConsulentesController
  Get.put(AttendanceController());
  Get.put(RecadoController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find<AppController>();

    return GetMaterialApp(
      title: 'ElosTupi',
      theme: appController.lightTheme,
      locale: LocaleConfig.defaultLocale,
      supportedLocales: const [Locale('pt', 'PT'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.noTransition,
      transitionDuration: Duration.zero,
      getPages: [
        GetPage(name: '/admin', page: () => const AdminScreen()),
        GetPage(
          name: '/admin/products',
          page: () => const AdminProductsScreen(),
        ),
        GetPage(
          name: '/membership',
          page: () => const MembershipScreen(),
          binding: MembershipBinding(),
        ),
        GetPage(
          name: '/electricity',
          page: () => const ElectricityReadingScreen(),
        ),
        GetPage(
          name: '/electricity/settings',
          page: () => const ElectricitySettingsScreen(),
        ),
        GetPage(
          name: '/bluetooth-printer',
          page: () => BluetoothPrinterScreen(),
        ),
        GetPage(name: '/consulentes', page: () => const ConsulentesScreen()),
        GetPage(name: '/attendance', page: () => const AttendanceScreen()),
        GetPage(name: '/recados', page: () => const RecadosScreen()),
      ],
    );
  }
}
