import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'app_controller.dart';

class CartController extends GetxController {
  final GetStorage _storage = GetStorage();
  final ProductService _productService = ProductService();
  
  final RxList<CartItem> items = <CartItem>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCartFromStorage();
  }

  void addToCart(Product product) {
    // Verificar se há stock disponível
    if (product.stock != null && product.stock! <= 0) {
      Get.snackbar(
        'Stock Indisponível',
        '${product.name} não está disponível no momento',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }

    final existingIndex = items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      // Verificar se não excede o stock disponível
      if (product.stock != null && items[existingIndex].quantity >= product.stock!) {
        Get.snackbar(
          'Stock Limitado',
          'Quantidade máxima de ${product.name} já está no carrinho',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
        return;
      }
      
      items[existingIndex].quantity++;
      items.refresh();
    } else {
      items.add(CartItem(product: product, quantity: 1));
    }
    
    saveCartToStorage();
    
    Get.snackbar(
      'Produto Adicionado',
      '${product.name} foi adicionado ao carrinho',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  void removeFromCart(String productId) {
    items.removeWhere((item) => item.product.id == productId);
    saveCartToStorage();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final product = items[index].product;
      
      // Verificar se não excede o stock disponível
      if (product.stock != null && quantity > product.stock!) {
        Get.snackbar(
          'Stock Insuficiente',
          'Quantidade solicitada excede o stock disponível (${product.stock} unidades)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
        return;
      }
      
      items[index].quantity = quantity;
      items.refresh();
      saveCartToStorage();
    }
  }

  void clearCart() {
    items.clear();
    saveCartToStorage();
  }

  double get totalPrice {
    final AppController appController = Get.find<AppController>();
    return items.fold(0.0, (sum, item) {
      final price = appController.showResalePrice.value && item.product.price2 != null 
          ? item.product.price2! 
          : item.product.price;
      return sum + (price * item.quantity);
    });
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get isEmpty => items.isEmpty;

  Future<void> saveCartToStorage() async {
    try {
      final List<Map<String, dynamic>> cartJson = items.map((item) => {
        'product': item.product.toJson(),
        'quantity': item.quantity,
      }).toList();
      
      await _storage.write('cart_items', cartJson);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          if (kDebugMode) {
            if (kDebugMode) {
              if (kDebugMode) {
                if (kDebugMode) {
                  print('Erro ao salvar carrinho: $e');
                }
              }
            }
          }
        }
      }
    }
  }

  Future<void> loadCartFromStorage() async {
    try {
      final List<dynamic>? cartJson = _storage.read('cart_items');
      if (cartJson != null) {
        items.value = cartJson.map((json) => CartItem(
          product: Product.fromJson(json['product']),
          quantity: json['quantity'],
        )).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar carrinho: $e');
      }
    }
  }

  // Finalizar compra e atualizar stock
  Future<bool> finalizeOrder() async {
    if (items.isEmpty) return false;
    
    isLoading.value = true;
    
    try {
      // Atualizar stock para cada item
      for (final item in items) {
        print('[CART] Tentando decrementar stock de ${item.product.id} (${item.product.name}), quantidade: ${item.quantity}');
        final result = await _productService.decrementStock(
          item.product.id, 
          item.quantity
        );
        print('[CART] Resultado: success=${result['success']}, message=${result['message']}');
        
        if (!(result['success'] ?? false)) {
          Get.snackbar(
            'Erro na Compra',
            result['message'] ?? 'Erro ao atualizar stock de ${item.product.name}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          isLoading.value = false;
          return false;
        }
      }
      
      // Limpar carrinho após sucesso
      clearCart();
      
      Get.snackbar(
        'Compra Finalizada!',
        'Pedido realizado com sucesso. Stock atualizado.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      isLoading.value = false;
      return true;
      
    } catch (e) {
      isLoading.value = false;
      print('[CART] Exceção finalizeOrder: $e');
      Get.snackbar(
        'Erro na Compra',
        'Erro ao finalizar pedido: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });
} 