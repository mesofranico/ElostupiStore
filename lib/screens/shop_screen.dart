import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import '../controllers/cart_controller.dart';
import '../widgets/product_card.dart';
import '../widgets/standard_appbar.dart';
import '../widgets/loading_view.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final ProductController productController = Get.find<ProductController>();
  late Worker _productsWorker;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _scrollController = ScrollController();

    // Observar mudanças nas categorias para atualizar o TabController
    _productsWorker = ever(productController.products, (_) {
      _updateTabController();
    });
  }

  void _updateTabController() {
    if (!mounted) return;

    final categories = productController.categories;
    if (categories.length != _tabController.length) {
      _tabController.dispose();
      _tabController = TabController(length: categories.length, vsync: this);

      // Adicionar listener para detectar mudanças de tab
      _tabController.addListener(() {
        if (_tabController.indexIsChanging && mounted) {
          final currentIndex = _tabController.index;
          if (currentIndex >= 0 && currentIndex < categories.length) {
            final selectedCategory = categories[currentIndex];
            productController.setCategory(selectedCategory);
          }
        }
      });

      // Definir índice inicial baseado na categoria selecionada
      if (categories.isNotEmpty) {
        final selectedCategory = productController.selectedCategory.value;
        final categoryIndex = categories.indexOf(selectedCategory);

        // Se a categoria selecionada existe na lista, usar seu índice
        if (categoryIndex >= 0 && categoryIndex < categories.length) {
          _tabController.index = categoryIndex;
        } else {
          // Caso contrário, usar índice 0 (primeira categoria)
          _tabController.index = 0;
          productController.setCategory(categories[0]);
        }

        // Forçar rebuild do widget
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  @override
  void dispose() {
    _productsWorker.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  Widget _buildBody() {
    return Obx(() {
      if (productController.isLoading.value) {
        return const LoadingView();
      }

      if (productController.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                productController.isOfflineMode
                    ? Icons.wifi_off
                    : Icons.error_outline,
                size: 64,
                color: productController.isOfflineMode
                    ? Colors.orange[300]
                    : Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                productController.isOfflineMode
                    ? 'Modo Offline'
                    : 'Erro ao carregar produtos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: productController.isOfflineMode
                      ? Colors.orange[300]
                      : Colors.red[300],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  productController.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              if (productController.selectedCategory.value != 'Todas') ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    productController.setCategory('Todas');

                    // Verificar se o índice é válido antes de definir
                    if (_tabController.length > 0) {
                      _tabController.index = 0;
                    }
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

      final padding = _getPadding(context);
      return GridView.builder(
        padding: EdgeInsets.fromLTRB(padding, padding, padding, padding + 100),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          return ProductCard(product: filteredProducts[index]);
        },
      );
    });
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    return Obx(() {
      final categories = productController.categories;
      if (categories.length <= 1) {
        return const SizedBox.shrink();
      }
      return Container(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                if (categories.length > 4)
                  Container(
                    width: 40,
                    color: theme.colorScheme.surface,
                    child: IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        _scrollController.jumpTo(
                          (_scrollController.offset - 150).clamp(
                            0.0,
                            _scrollController.position.maxScrollExtent,
                          ),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.asMap().entries.map((entry) {
                        final index = entry.key;
                        final category = entry.value;
                        final isSelected =
                            productController.selectedCategory.value ==
                            category;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              productController.setCategory(category);
                              if (index >= 0 && index < _tabController.length) {
                                _tabController.index = index;
                                _scrollToSelectedTab(index);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant
                                            .withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                category,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (categories.length > 4)
                  Container(
                    width: 40,
                    color: theme.colorScheme.surface,
                    child: IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        _scrollController.jumpTo(
                          (_scrollController.offset + 150).clamp(
                            0.0,
                            _scrollController.position.maxScrollExtent,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // Método para scroll para centralizar a tab selecionada
  void _scrollToSelectedTab(int index) {
    // Calcular a posição aproximada da tab
    final tabWidth = 140.0; // Largura aproximada de cada tab (incluindo margin)
    final targetOffset = index * tabWidth;

    // Scroll para centralizar a tab
    final maxScroll = _scrollController.position.maxScrollExtent;
    final viewportWidth = _scrollController.position.viewportDimension;
    final scrollTo = (targetOffset - (viewportWidth / 2) + (tabWidth / 2))
        .clamp(0.0, maxScroll);

    _scrollController.jumpTo(scrollTo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final CartController cartController = Get.find<CartController>();

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Loja',
        backgroundColor: theme.colorScheme.primary,
        actions: [
          Obx(() {
            final totalItems = cartController.totalItems;
            if (totalItems > 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Stack(
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red[500],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$totalItems',
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
                  ),
                  onPressed: () => Get.toNamed('/cart'),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            if (productController.isOfflineMode) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OFFLINE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildTabBar(),
        ),
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
