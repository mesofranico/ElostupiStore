import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import '../controllers/cart_controller.dart';
import 'dashboard_screen.dart';
import 'shop_screen.dart';
import 'reports_screen.dart';
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
      navBarBuilder: (navBarConfig) =>
          Style2BottomNavBar(navBarConfig: navBarConfig),
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
        screen: const ReportsScreen(),
        item: ItemConfig(
          icon: const Icon(Icons.analytics),
          inactiveIcon: const Icon(Icons.analytics_outlined),
          title: "Relatórios",
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
