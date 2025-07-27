import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../controllers/app_controller.dart';
import '../widgets/cart_item_widget.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Obx(() {
            if (cartController.totalItems > 0) {
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      title: const Text('Limpar Carrinho'),
                      content: const Text('Tem certeza que deseja remover todos os itens?'),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            cartController.clearCart();
                            Get.back();
                          },
                          child: const Text('Limpar'),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (cartController.items.isEmpty) {
            return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 100,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Seu carrinho está vazio',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Adicione alguns produtos para começar!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cartController.items.length,
                itemBuilder: (context, index) {
                  return CartItemWidget(cartItem: cartController.items[index]);
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.15),
                    spreadRadius: 2,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Valor Total:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Obx(() => Text(
                              '€${cartController.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        final appController = Get.find<AppController>();
                        final isResale = appController.showResalePrice.value;
                        final totalItems = cartController.totalItems;
                        final uniqueItems = cartController.items.length;
                        
                        return Text(
                          '$totalItems ${totalItems == 1 ? 'item' : 'itens'} • ${uniqueItems == 1 ? '1 produto' : '$uniqueItems produtos'} • ${isResale ? 'Preço Corrente' : 'Preço Consulente'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Obx(() => Row(
                    children: [
                      // Botão Salvar como Pendente
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Colors.orange, Colors.orange[700]!],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withAlpha((0.3 * 255).toInt()),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: cartController.isLoading.value
                                  ? null
                                  : () async {
                                      final ok = await cartController.savePendingOrderAPI();
                                      if (ok) {
                                        cartController.clearCart();
                                        Get.snackbar(
                                          'Pedido Pendente',
                                          'O pedido foi salvo como pendente na nuvem. Você pode finalizar depois.',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: Colors.orange.withAlpha((0.9 * 255).toInt()),
                                          colorText: Colors.white,
                                          duration: const Duration(seconds: 3),
                                        );
                                        Get.back();
                                      } else {
                                        Get.snackbar(
                                          'Erro',
                                          'Não foi possível salvar o pedido pendente. Tente novamente.',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: Colors.red.withAlpha((0.9 * 255).toInt()),
                                          colorText: Colors.white,
                                          duration: const Duration(seconds: 3),
                                        );
                                      }
                                    },
                              child: Center(
                                child: cartController.isLoading.value
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Processando...',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.hourglass_empty,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Guardar Pedido',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botão Finalizar Compra
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Colors.green, Colors.green[700]!],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withAlpha((0.4 * 255).toInt()),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: cartController.isLoading.value
                                  ? null
                                  : () async {
                                      final success = await cartController.finalizeOrder();
                                      if (success) {
                                        Get.back();
                                      }
                                    },
                              child: Center(
                                child: cartController.isLoading.value
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Processando...',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.payment,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Finalizar Pedido',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ],
        );
        }),
      ),
    );
  }
} 