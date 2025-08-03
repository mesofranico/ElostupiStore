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
      
      // Definir categoria inicial como "Todas" apenas se não houver categoria selecionada
      if (categories.isNotEmpty && productController.selectedCategory.value == 'Todas') {
        // Forçar rebuild do widget
        setState(() {});
      }
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  productController.selectedCategory.value == 'Todas'
                      ? 'Carregando produtos...'
                      : 'Carregando ${productController.selectedCategory.value}...',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aguarde um momento',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  productController.selectedCategory.value == 'Todas' 
                      ? Icons.inventory_2_outlined
                      : Icons.category_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  productController.selectedCategory.value == 'Todas'
                      ? 'Nenhum produto encontrado'
                      : 'Nenhum produto em "${productController.selectedCategory.value}"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  productController.searchQuery.value.isNotEmpty
                      ? 'Tente ajustar sua pesquisa'
                      : 'Esta categoria ainda não tem produtos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (productController.selectedCategory.value != 'Todas') ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      productController.setCategory('Todas');
                      _tabController.animateTo(0);
                    },
                    icon: const Icon(Icons.grid_view),
                    label: const Text('Ver Todos os Produtos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            _getPadding(Get.context!),
            _getPadding(Get.context!),
            _getPadding(Get.context!),
            _getPadding(Get.context!) + 20, // Padding extra na parte inferior
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(Get.context!),
            childAspectRatio: _getChildAspectRatio(Get.context!),
            crossAxisSpacing: _getSpacing(Get.context!),
            mainAxisSpacing: _getSpacing(Get.context!),
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ProductCard(product: filteredProducts[index]),
            );
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
        child: SafeArea(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final isSelected = productController.selectedCategory.value == category;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      productController.setCategory(category);
                      _tabController.animateTo(index);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.blue : Colors.grey[500],
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          width: isSelected ? 30 : 20,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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
              'ElosTupi - Gestão',
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
          preferredSize: const Size.fromHeight(60),
          child: _buildTabBar(),
        ),
        actions: [
          Obx(() {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    final future = Get.to(() => const CartScreen());
                    if (future != null) {
                      future.then((_) {
                        final productController = Get.find<ProductController>();
                        final cartController = Get.find<CartController>();
                        productController.refreshProducts();
                        cartController.updatePendingOrders();
                      });
                    }
                  },
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
         Obx(() {
           final pendingCount = cartController.pendingOrders.length;
           return Stack(
             clipBehavior: Clip.none,
             children: [
               IconButton(
                 icon: const Icon(Icons.pending_actions),
                 tooltip: 'Pedidos Pendentes',
                 onPressed: () {
                   final future = Get.toNamed('/pendentes');
                   if (future != null) {
                     future.then((_) {
                       final productController = Get.find<ProductController>();
                       final cartController = Get.find<CartController>();
                       productController.refreshProducts();
                       cartController.updatePendingOrders();
                     });
                   }
                 },
               ),
               if (pendingCount > 0)
                 Positioned(
                   right: 2,
                   top: 8,
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                     decoration: BoxDecoration(
                       color: Colors.orange,
                       borderRadius: BorderRadius.circular(10),
                       border: Border.all(color: Colors.white, width: 1),
                     ),
                     constraints: const BoxConstraints(
                       minWidth: 14,
                       minHeight: 14,
                     ),
                     child: Text(
                       pendingCount > 99 ? '99+' : '$pendingCount',
                       style: const TextStyle(
                         color: Colors.white,
                         fontSize: 9,
                         fontWeight: FontWeight.bold,
                         height: 1,
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