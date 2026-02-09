import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../controllers/app_controller.dart';
import '../models/cart_item.dart';

String getFullImageUrl(String imageUrl) {
  if (imageUrl.isEmpty) return '';
  if (imageUrl.startsWith('http')) return imageUrl;
  return 'https://gestao.elostupi.pt/$imageUrl';
}

class CartItemWidget extends StatelessWidget {
  static const double cardRadius = 10;
  static const double imageRadius = 6;
  static const double contentPadding = 6;
  static const double buttonRadius = 6;
  static const double minButtonHeight = 28;
  static const double imageSize = 72;

  final CartItem cartItem;

  const CartItemWidget({
    super.key,
    required this.cartItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final CartController cartController = Get.find<CartController>();
    final AppController appController = Get.find<AppController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(contentPadding + 2),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(imageRadius),
              child: SizedBox(
                width: imageSize,
                height: imageSize,
                child: Image.network(
                  getFullImageUrl(cartItem.product.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    child: Icon(Icons.image_not_supported, size: 22, color: theme.colorScheme.outline),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cartItem.product.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Obx(() {
                    final displayPrice = appController.showResalePrice.value && cartItem.product.price2 != null
                        ? cartItem.product.price2!
                        : cartItem.product.price;
                    final isResale = appController.showResalePrice.value && cartItem.product.price2 != null;
                    final bgColor = isResale ? Colors.orange.shade50 : Colors.green.shade50;
                    final borderColor = isResale ? Colors.orange.shade200 : Colors.green.shade200;
                    final textColor = isResale ? Colors.orange.shade800 : Colors.green.shade800;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(buttonRadius),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        '€${displayPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 2),
                  Obx(() {
                    final displayPrice = appController.showResalePrice.value && cartItem.product.price2 != null
                        ? cartItem.product.price2!
                        : cartItem.product.price;
                    return Text(
                      'Subtotal: €${(displayPrice * cartItem.quantity).toStringAsFixed(2)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    );
                  }),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(buttonRadius),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => cartController.updateQuantity(
                            cartItem.product.id,
                            cartItem.quantity - 1,
                          ),
                          borderRadius: BorderRadius.circular(buttonRadius - 2),
                          child: SizedBox(
                            width: minButtonHeight - 4,
                            height: minButtonHeight - 4,
                            child: Icon(Icons.remove, size: 16, color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${cartItem.quantity}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => cartController.updateQuantity(
                            cartItem.product.id,
                            cartItem.quantity + 1,
                          ),
                          borderRadius: BorderRadius.circular(buttonRadius - 2),
                          child: SizedBox(
                            width: minButtonHeight - 4,
                            height: minButtonHeight - 4,
                            child: Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => cartController.removeFromCart(cartItem.product.id),
                    borderRadius: BorderRadius.circular(buttonRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(buttonRadius),
                        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, size: 14, color: theme.colorScheme.error),
                          const SizedBox(width: 4),
                          Text(
                            'Remover',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
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
