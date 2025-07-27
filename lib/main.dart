import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/storage_init.dart';
import 'core/locale_config.dart';
import 'controllers/app_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/cart_controller.dart';
import 'screens/shop_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/pending_orders_screen.dart';
import 'screens/membership_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageInit.init();
  
  // Inicializar controllers na ordem correta
  Get.put(AppController());
  Get.put(CartController()); // CartController primeiro
  Get.put(ProductController()); // ProductController depois
  
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
      home: const ShopScreen(),
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      getPages: [
        GetPage(name: '/admin', page: () => const AdminScreen()),
        GetPage(name: '/pendentes', page: () => const PendingOrdersScreen()),
        GetPage(name: '/membership', page: () => const MembershipScreen()),
      ],
    );
  }
}
