import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../controllers/app_controller.dart';
import '../models/cart_item.dart';

// Função utilitária para montar a URL completa da imagem
String getFullImageUrl(String imageUrl) {
  if (imageUrl.isEmpty) return '';
  if (imageUrl.startsWith('http')) return imageUrl;
  return 'https://gestao.elostupi.pt/$imageUrl';
}

class CartItemWidget extends StatelessWidget {
  final CartItem cartItem;

  const CartItemWidget({
    super.key,
    required this.cartItem,
  });

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();
    final AppController appController = Get.find<AppController>();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  getFullImageUrl(cartItem.product.imageUrl),
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey[100],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 30,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.product.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Obx(() {
                    final displayPrice = appController.showResalePrice.value && cartItem.product.price2 != null 
                        ? cartItem.product.price2! 
                        : cartItem.product.price;
                    final isResalePrice = appController.showResalePrice.value && cartItem.product.price2 != null;
                    
                    return Text(
                      '€${displayPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isResalePrice ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  Obx(() {
                    final displayPrice = appController.showResalePrice.value && cartItem.product.price2 != null 
                        ? cartItem.product.price2! 
                        : cartItem.product.price;
                    final isResalePrice = appController.showResalePrice.value && cartItem.product.price2 != null;
                    
                    return Text(
                      'Subtotal: €${(displayPrice * cartItem.quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isResalePrice ? Colors.orange[600] : Colors.grey,
                      ),
                    );
                  }),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () {
                            cartController.updateQuantity(
                              cartItem.product.id,
                              cartItem.quantity - 1,
                            );
                          },
                          icon: const Icon(Icons.remove, size: 18),
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '${cartItem.quantity}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () {
                            cartController.updateQuantity(
                              cartItem.product.id,
                              cartItem.quantity + 1,
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        cartController.removeFromCart(cartItem.product.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.delete,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Remover',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 