import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/product_service.dart';
import 'app_controller.dart';
import '../services/pending_order_service.dart';
import '../services/bluetooth_print_service.dart';

class CartController extends GetxController {
  final GetStorage _storage = GetStorage();
  final ProductService _productService = ProductService();
  final PendingOrderService _pendingOrderService = PendingOrderService();
  final BluetoothPrintService _bluetoothService = Get.find<BluetoothPrintService>();
  
  final RxList<CartItem> items = <CartItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> pendingOrders = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCartFromStorage();
    updatePendingOrders();
  }

  void addToCart(Product product) {
    // Verificar se há stock disponível
    if (product.stock != null && product.stock! <= 0) {
      // Não mostrar snackbar - o estado já é visível no card
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
    
    // Ativar wake lock temporariamente durante a operação
    final appController = Get.find<AppController>();
    appController.enableWakeLockTemporarily();
    
    isLoading.value = true;
    
    try {
      // Atualizar stock para cada item
      for (final item in items) {
        if (kDebugMode) {
          print('[CART] Tentando decrementar stock de ${item.product.id} (${item.product.name}), quantidade: ${item.quantity}');
        }
        final result = await _productService.decrementStock(
          item.product.id, 
          item.quantity
        );
        if (kDebugMode) {
          print('[CART] Resultado: success=${result['success']}, message=${result['message']}');
        }
        
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
      
      // Tentar imprimir talão
      await _printReceipt();
      
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
      if (kDebugMode) {
        print('[CART] Exceção finalizeOrder: $e');
      }
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

  // Imprimir talão da compra
  Future<void> _printReceipt() async {
    try {
      await _bluetoothService.printReceipt(
        items: items.toList(),
        total: totalPrice,
      );
    } catch (e) {
      // Não mostrar erro ao utilizador se a impressão falhar
      // A compra já foi finalizada com sucesso
    }
  }

  // Salvar pedido como pendente (API)
  Future<bool> savePendingOrderAPI({required String note}) async {
    if (items.isEmpty) return false;
    final List<Map<String, dynamic>> orderItems = items.map((item) => {
      'product': {
        'id': item.product.id,
        'name': item.product.name,
        'price': item.product.price,
        'price2': item.product.price2,
      },
      'quantity': item.quantity,
    }).toList();
    final now = DateTime.now();
    final id = '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final createdAt = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final order = {
      'id': id,
      'createdAt': createdAt,
      'items': orderItems,
      'total': totalPrice,
      'note': note.trim(),
    };
    isLoading.value = true;
    try {
      final ok = await _pendingOrderService.createPendingOrder(order);
      isLoading.value = false;
      return ok;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) print('Erro ao salvar pendente: $e');
      return false;
    }
  }

  // Listar pedidos pendentes (API)
  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    try {
      return await _pendingOrderService.getPendingOrders();
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar pendentes: $e');
      return [];
    }
  }

  // Remover pedido pendente (API)
  Future<bool> removePendingOrderAPI(String id) async {
    isLoading.value = true;
    try {
      final ok = await _pendingOrderService.removePendingOrder(id);
      isLoading.value = false;
      return ok;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) print('Erro ao remover pendente: $e');
      return false;
    }
  }

  // Finalizar pedido pendente (API)
  Future<bool> finalizePendingOrderAPI(String id) async {
    isLoading.value = true;
    try {
      final ok = await _pendingOrderService.finalizePendingOrder(id);
      if (ok) {
        // Tentar imprimir talão do pedido finalizado
        await _printPendingOrderReceipt(id);
      }
      isLoading.value = false;
      return ok;
    } catch (e) {
      isLoading.value = false;
      if (kDebugMode) print('Erro ao finalizar pendente: $e');
      return false;
    }
  }

  // Imprimir talão de pedido pendente finalizado
  Future<void> _printPendingOrderReceipt(String orderId) async {
    try {
      // Encontrar o pedido na lista de pendentes
      final orderList = pendingOrders.where((order) => order['id'] == orderId).toList();
      if (orderList.isEmpty) return;
      final order = orderList.first;

      // Converter itens do pedido para CartItem
      final List<CartItem> orderItems = [];
      final List<dynamic> items = order['items'] ?? [];
      
      for (final item in items) {
        final productData = item['product'];
        final product = Product(
          id: productData['id'],
          name: productData['name'],
          price: double.tryParse(productData['price'].toString()) ?? 0.0,
          price2: double.tryParse(productData['price2'].toString()) ?? 0.0,
          description: productData['description'] ?? '', // Adicionar descrição
          stock: 0, // Não relevante para impressão
          imageUrl: '', // Não relevante para impressão
        );
        
        orderItems.add(CartItem(
          product: product,
          quantity: item['quantity'] ?? 1,
        ));
      }

      final total = double.tryParse(order['total'].toString()) ?? 0.0;
      final note = order['note'] as String?;

      // Imprimir talão
      await _bluetoothService.printReceipt(
        items: orderItems,
        total: total,
        note: note,
      );
    } catch (e) {
      // Não mostrar erro ao utilizador se a impressão falhar
      // O pedido já foi finalizado com sucesso
    }
  }

  // Atualizar lista de pedidos pendentes da API
  Future<void> updatePendingOrders() async {
    try {
      final list = await _pendingOrderService.getPendingOrders();
      pendingOrders.value = list;
    } catch (e) {
      if (kDebugMode) print('Erro ao atualizar pendentes: $e');
      pendingOrders.clear();
    }
  }
}

 