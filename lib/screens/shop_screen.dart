import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import '../controllers/cart_controller.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'settings_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ProductController productController = Get.find<ProductController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    
    // Observar mudanças nas categorias para atualizar o TabController
    ever(productController.products, (_) {
      _updateTabController();
    });
  }

  void _updateTabController() {
    final categories = productController.categories;
    if (categories.length != _tabController.length) {
      _tabController.dispose();
      _tabController = TabController(length: categories.length, vsync: this);
      
      // Adicionar listener para detectar mudanças de tab
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          final selectedCategory = categories[_tabController.index];
          productController.setCategory(selectedCategory);
        }
      });
      
      // Definir categoria inicial como "Todas"
      productController.setCategory('Todas');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Calcula o número de colunas baseado no tamanho da tela
  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      return 5; // Desktop grande
    } else if (screenWidth >= 900) {
      return 4; // Desktop pequeno / Tablet grande
    } else if (screenWidth >= 600) {
      return 3; // Tablet
    } else {
      return 2; // Smartphone
    }
  }

  // Calcula o aspect ratio baseado no tamanho da tela
  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      return 0.85; // Desktop grande - cards mais altos
    } else if (screenWidth >= 900) {
      return 0.8; // Desktop pequeno / Tablet grande
    } else if (screenWidth >= 600) {
      return 0.75; // Tablet
    } else {
      return 0.75; // Smartphone
    }
  }

  // Calcula o padding baseado no tamanho da tela
  double _getPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      return 16; // Desktop grande
    } else if (screenWidth >= 900) {
      return 12; // Desktop pequeno / Tablet grande
    } else if (screenWidth >= 600) {
      return 10; // Tablet
    } else {
      return 8; // Smartphone
    }
  }

  // Calcula o espaçamento entre cards baseado no tamanho da tela
  double _getSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      return 12; // Desktop grande
    } else if (screenWidth >= 900) {
      return 10; // Desktop pequeno / Tablet grande
    } else if (screenWidth >= 600) {
      return 8; // Tablet
    } else {
      return 8; // Smartphone
    }
  }

  Widget _buildBody() {
    return Obx(() {
      if (productController.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Carregando produtos...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        if (productController.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  productController.isOfflineMode ? Icons.wifi_off : Icons.error_outline,
                  size: 64,
                  color: productController.isOfflineMode ? Colors.orange[300] : Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  productController.isOfflineMode ? 'Modo Offline' : 'Erro ao carregar produtos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: productController.isOfflineMode ? Colors.orange[300] : Colors.red[300],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    productController.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: productController.refreshProducts,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (productController.isOfflineMode) ...[
                      const SizedBox(width: 16),
                                             ElevatedButton.icon(
                         onPressed: () {
                           // Mostrar informação sobre modo offline
                         },
                         icon: const Icon(Icons.info),
                         label: const Text('Sobre'),
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.grey[600],
                           foregroundColor: Colors.white,
                         ),
                       ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }

        final filteredProducts = productController.filteredProducts;

        if (filteredProducts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum produto encontrado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(_getPadding(Get.context!)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(Get.context!),
            childAspectRatio: _getChildAspectRatio(Get.context!),
            crossAxisSpacing: _getSpacing(Get.context!),
            mainAxisSpacing: _getSpacing(Get.context!),
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            return ProductCard(product: filteredProducts[index]);
          },
        );
      });
  }

  Widget _buildTabBar() {
    return Obx(() {
      final categories = productController.categories;
      
      if (categories.length <= 1) {
        return const SizedBox.shrink(); // Não mostrar tabs se só há "Todas"
      }
      
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: categories.map((category) {
            return Tab(
              text: category,
            );
          }).toList(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'ElosTupi - Gestão de produtos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
                         Obx(() {
               if (productController.isOfflineMode) {
                return Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'OFFLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildTabBar(),
        ),
        actions: [
          Obx(() {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => Get.to(() => const CartScreen()),
                ),
                if (cartController.totalItems > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${cartController.totalItems}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => const SettingsScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await productController.refreshProducts();
        },
        child: _buildBody(),
      ),
    );
  }
} 