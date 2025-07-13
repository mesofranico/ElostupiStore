import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/storage_init.dart';
import 'controllers/app_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/cart_controller.dart';
import 'screens/shop_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageInit.init();
  
  // Inicializar controllers
  Get.put(AppController());
  Get.put(ProductController());
  Get.put(CartController());
  
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
      home: const ShopScreen(),
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
