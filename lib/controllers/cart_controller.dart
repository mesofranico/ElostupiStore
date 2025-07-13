import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/product.dart';

class CartController extends GetxController {
  final GetStorage _storage = GetStorage();
  
  final RxList<CartItem> items = <CartItem>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCartFromStorage();
  }

  void addToCart(Product product) {
    final existingIndex = items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
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
    return items.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
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
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });
} 