import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'cart_controller.dart';

class ProductController extends GetxController {
  final ProductService _productService = ProductService();
  final GetStorage _storage = GetStorage();

  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'Todas'.obs;
  final RxBool hasCachedData = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();

    // Inicializar ordem das categorias
    _initializeCategoryOrder();

    // Observar mudanças no carrinho para atualizar indicadores de stock
    // Verificar se o CartController já foi inicializado
    try {
      final cartController = Get.find<CartController>();
      ever(cartController.items, (_) {
        _updateStockIndicators();
      });
    } catch (e) {
      // CartController ainda não foi inicializado, tentar novamente mais tarde
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          final cartController = Get.find<CartController>();
          ever(cartController.items, (_) {
            _updateStockIndicators();
          });
        } catch (e) {
          if (kDebugMode) {
            print('CartController não encontrado: $e');
          }
        }
      });
    }
  }

  // Inicializar ordem das categorias
  void _initializeCategoryOrder() {
    if (_customCategoryOrder.isEmpty) {
      _loadCategoryOrderFromAPI();
    }
  }

  void _updateStockIndicators() {
    // Forçar atualização dos indicadores de stock
    products.refresh();
  }

  // Calcular stock disponível considerando o carrinho e pedidos pendentes
  int getAvailableStock(Product product) {
    try {
      final cartController = Get.find<CartController>();
      final cartItem = cartController.items.firstWhereOrNull(
        (item) => item.product.id == product.id,
      );
      final cartQuantity = cartItem?.quantity ?? 0;
      // Somar quantidade em pedidos pendentes (reativo)
      int pendingQuantity = 0;
      final List<Map<String, dynamic>> pendingOrders =
          cartController.pendingOrders;
      for (final order in pendingOrders) {
        final List<dynamic> items = order['items'] ?? [];
        for (final item in items) {
          if (item['product']?['id']?.toString() == product.id) {
            final q = item['quantity'];
            pendingQuantity += (q is int)
                ? q
                : int.tryParse(q?.toString() ?? '') ?? 0;
          }
        }
      }
      final currentStock = product.stock ?? 0;
      return currentStock - cartQuantity - pendingQuantity;
    } catch (e) {
      // Se CartController não estiver disponível, retornar stock original
      return product.stock ?? 0;
    }
  }

  List<Product> getLowStockProducts([String category = 'Todas']) {
    try {
      if (category == 'Todas') {
        return products.where((p) {
          if (!p.manageStock) return false;
          final availableStock = getAvailableStock(p);
          return availableStock <= 5 && availableStock > 0;
        }).toList();
      }
      return products.where((p) {
        if (p.category != category) return false;
        if (!p.manageStock) return false;
        final availableStock = getAvailableStock(p);
        return availableStock <= 5 && availableStock > 0;
      }).toList();
    } catch (e) {
      if (category == 'Todas') {
        return products
            .where(
              (p) => p.manageStock && (p.stock ?? 0) <= 5 && (p.stock ?? 0) > 0,
            )
            .toList();
      }
      return products
          .where(
            (p) =>
                p.category == category &&
                p.manageStock &&
                (p.stock ?? 0) <= 5 &&
                (p.stock ?? 0) > 0,
          )
          .toList();
    }
  }

  int getLowStockCount(String category) {
    return getLowStockProducts(category).length;
  }

  // Verificar se há produtos sem stock (considerando carrinho)
  int getNoStockCount(String category) {
    try {
      if (category == 'Todas') {
        return products.where((p) {
          if (!p.manageStock) return false;
          final availableStock = getAvailableStock(p);
          return availableStock == 0;
        }).length;
      } else {
        return products.where((p) {
          if (p.category != category) return false;
          if (!p.manageStock) return false;
          final availableStock = getAvailableStock(p);
          return availableStock == 0;
        }).length;
      }
    } catch (e) {
      // Fallback para cálculo sem carrinho
      if (category == 'Todas') {
        return products
            .where((p) => p.manageStock && (p.stock ?? 0) == 0)
            .length;
      } else {
        return products
            .where(
              (p) =>
                  p.category == category &&
                  p.manageStock &&
                  (p.stock ?? 0) == 0,
            )
            .length;
      }
    }
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final List<Product> loadedProducts = await _productService.getProducts();
      products.value = loadedProducts;
      hasCachedData.value = false;

      // Salvar no cache local
      await _saveProductsToCache(loadedProducts);

      // Carregar ordem das categorias da API
      await _loadCategoryOrderFromAPI();
    } catch (e) {
      // Tentar carregar do cache
      final cachedProducts = await _loadProductsFromCache();

      if (cachedProducts.isNotEmpty) {
        products.value = cachedProducts;
        hasCachedData.value = true;
        errorMessage.value = _getFriendlyErrorMessage(e.toString());

        // Carregar ordem das categorias da API mesmo em modo offline
        await _loadCategoryOrderFromAPI();
      } else {
        errorMessage.value = _getFriendlyErrorMessage(e.toString());
        products.clear();
        hasCachedData.value = false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('SocketException') ||
        error.contains('NetworkException')) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    } else if (error.contains('TimeoutException')) {
      return 'Tempo limite excedido. A conexão está lenta, tente novamente.';
    } else if (error.contains('404') || error.contains('Not Found')) {
      return 'Produtos não encontrados no servidor. Tente novamente mais tarde.';
    } else if (error.contains('500') ||
        error.contains('Internal Server Error')) {
      return 'Erro no servidor. Tente novamente em alguns minutos.';
    } else if (error.contains('JSON')) {
      return 'Erro ao processar dados dos produtos. Tente novamente.';
    } else {
      return 'Não foi possível carregar os produtos. Tente novamente.';
    }
  }

  Future<void> _saveProductsToCache(List<Product> products) async {
    try {
      final List<Map<String, dynamic>> productsJson = products
          .map((p) => p.toJson())
          .toList();
      await _storage.write('cached_products', productsJson);
      await _storage.write(
        'cache_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar cache: $e');
      }
    }
  }

  Future<List<Product>> _loadProductsFromCache() async {
    try {
      final List<dynamic>? productsJson = _storage.read('cached_products');
      if (productsJson != null) {
        return productsJson.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar cache: $e');
      }
    }
    return [];
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setCategory(String category) {
    selectedCategory.value = category;
  }

  List<Product> get filteredProducts {
    List<Product> filtered = products;

    // Filtrar por categoria
    if (selectedCategory.value != 'Todas') {
      filtered = filtered
          .where((product) => product.category == selectedCategory.value)
          .toList();
    }

    // Filtrar por pesquisa
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where(
            (product) =>
                product.name.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ) ||
                product.description.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ),
          )
          .toList();
    }

    return filtered;
  }

  // Ordem personalizada das categorias (salva online)
  final RxList<String> _customCategoryOrder = <String>[].obs;

  List<String> get categories {
    final Set<String> categories = products
        .map((p) => p.category)
        .where((c) => c != null)
        .cast<String>()
        .toSet();

    // Obter categorias na ordem personalizada
    final List<String> orderedCategories = [];

    // Adicionar 'Todas' sempre primeiro
    orderedCategories.add('Todas');

    // Adicionar categorias na ordem personalizada
    for (final category in _customCategoryOrder) {
      if (categories.contains(category)) {
        orderedCategories.add(category);
      }
    }

    // Adicionar categorias novas que não estão na ordem personalizada
    final newCategories =
        categories
            .where((category) => !_customCategoryOrder.contains(category))
            .toList()
          ..sort();

    orderedCategories.addAll(newCategories);

    return orderedCategories;
  }

  // Carregar ordem das categorias da API
  Future<void> _loadCategoryOrderFromAPI() async {
    try {
      final response = await _productService.getCategoryOrder();
      if (response.isNotEmpty) {
        _customCategoryOrder.value = response;
      } else {
        // Se não há ordem definida na API, sincronizar com produtos atuais
        await _syncCategoriesWithAPI();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar ordem das categorias da API: $e');
      }
      // Em caso de erro, usar ordem alfabética
      final Set<String> categories = products
          .map((p) => p.category)
          .where((c) => c != null)
          .cast<String>()
          .toSet();
      final sortedCategories = categories.toList()..sort();
      _customCategoryOrder.value = sortedCategories;
    }
  }

  // Sincronizar categorias com a API
  Future<void> _syncCategoriesWithAPI() async {
    try {
      final response = await _productService.syncCategories();
      if (response.isNotEmpty) {
        _customCategoryOrder.value = response;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao sincronizar categorias: $e');
      }
    }
  }

  // Método para reordenar categorias (salva na API)
  Future<void> reorderCategories(List<String> newOrder) async {
    try {
      await _productService.updateCategoryOrder(newOrder);
      _customCategoryOrder.value = newOrder;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao atualizar ordem das categorias: $e');
      }
      // Em caso de erro, atualizar localmente
      _customCategoryOrder.value = newOrder;
    }
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }

  bool get isOfflineMode => hasCachedData.value;

  Future<void> refreshData() async {
    products.clear();
    errorMessage.value = '';
    try {
      await _storage.remove('cached_products');
      await _storage.remove('cache_timestamp');
    } catch (_) {}
    await loadProducts();
  }
}
