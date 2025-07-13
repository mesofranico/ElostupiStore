import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/product.dart';
import '../services/product_service.dart';

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
      
    } catch (e) {
      // Tentar carregar do cache
      final cachedProducts = await _loadProductsFromCache();
      
      if (cachedProducts.isNotEmpty) {
        products.value = cachedProducts;
        hasCachedData.value = true;
        errorMessage.value = _getFriendlyErrorMessage(e.toString());
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
    if (error.contains('SocketException') || error.contains('NetworkException')) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    } else if (error.contains('TimeoutException')) {
      return 'Tempo limite excedido. A conexão está lenta, tente novamente.';
    } else if (error.contains('404') || error.contains('Not Found')) {
      return 'Produtos não encontrados no servidor. Tente novamente mais tarde.';
    } else if (error.contains('500') || error.contains('Internal Server Error')) {
      return 'Erro no servidor. Tente novamente em alguns minutos.';
    } else if (error.contains('JSON')) {
      return 'Erro ao processar dados dos produtos. Tente novamente.';
    } else {
      return 'Não foi possível carregar os produtos. Tente novamente.';
    }
  }

  Future<void> _saveProductsToCache(List<Product> products) async {
    try {
      final List<Map<String, dynamic>> productsJson = 
          products.map((p) => p.toJson()).toList();
      await _storage.write('cached_products', productsJson);
      await _storage.write('cache_timestamp', DateTime.now().millisecondsSinceEpoch);
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
      filtered = filtered.where((product) => 
          product.category == selectedCategory.value).toList();
    }
    
    // Filtrar por pesquisa
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          product.description.toLowerCase().contains(searchQuery.value.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  List<String> get categories {
    final Set<String> categories = products.map((p) => p.category).where((c) => c != null).cast<String>().toSet();
    return ['Todas', ...categories.toList()..sort()];
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }

  bool get isOfflineMode => hasCachedData.value;
} 