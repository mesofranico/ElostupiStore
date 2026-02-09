import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import '../controllers/cart_controller.dart';
import 'dashboard_screen.dart';
import 'shop_screen.dart';
import 'cart_screen.dart';
import 'admin_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final PersistentTabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = PersistentTabController(initialIndex: 2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    return PersistentTabView(
      controller: _tabController,
      tabs: _buildTabs(cartController),
      navBarBuilder: (navBarConfig) => Style2BottomNavBar(
        navBarConfig: navBarConfig,
      ),
    );
  }

  List<PersistentTabConfig> _buildTabs(CartController cartController) {
    return [
      PersistentTabConfig(
        screen: const ShopScreen(),
        item: ItemConfig(
          icon: const Icon(Icons.storefront_outlined),
          title: "Loja",
        ),
      ),
      PersistentTabConfig(
        screen: const CartScreen(),
        item: ItemConfig(
          icon: Obx(() {
            final totalItems = cartController.totalItems;
            if (totalItems > 0) {
              return Stack(
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red[500],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 0),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$totalItems',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return const Icon(Icons.shopping_cart_outlined);
          }),
          title: "Carrinho",
        ),
      ),
      PersistentTabConfig(
        screen: const DashboardScreen(),
        item: ItemConfig(
          icon: const Icon(Icons.home, size: 28),
          inactiveIcon: const Icon(Icons.home_outlined, size: 26),
          title: "Início",
          activeForegroundColor: Colors.blue,
          iconSize: 28,
        ),
      ),
      PersistentTabConfig(
        screen: const AdminScreen(),
        item: ItemConfig(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          title: "Admin",
        ),
      ),
      PersistentTabConfig(
        screen: const SettingsScreen(),
        item: ItemConfig(
          icon: const Icon(Icons.tune_outlined),
          title: "Definições",
        ),
      ),
    ];
  }
}
