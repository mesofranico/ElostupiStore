import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../controllers/cart_controller.dart';
import '../controllers/app_controller.dart';
import '../controllers/product_controller.dart';

class ProductCard extends StatefulWidget {
  static const double cardRadius = 10;
  static const double imageRadius = 6;
  static const double contentPadding = 6;
  static const double buttonRadius = 6;
  static const double minButtonHeight = 28;
  static const double imageWidthFraction = 0.4;

  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _showFeedback = false;
  int _feedbackQuantity = 0;
  bool _fadingOut = false;
  Timer? _feedbackTimer;
  int _feedbackGeneration = 0;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _onAddPressed(CartController cartController) {
    cartController.addToCart(widget.product);
    _feedbackTimer?.cancel();
    _feedbackGeneration++;
    final generation = _feedbackGeneration;
    final sessionCount = (_showFeedback ? _feedbackQuantity : 0) + 1;
    setState(() {
      _showFeedback = true;
      _feedbackQuantity = sessionCount;
      _fadingOut = false;
    });
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || generation != _feedbackGeneration) return;
      setState(() => _fadingOut = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || generation != _feedbackGeneration) return;
        setState(() {
          _showFeedback = false;
          _fadingOut = false;
          _feedbackQuantity = 0;
        });
        _feedbackTimer = null;
      });
    });
  }

  String getFullImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    return 'https://gestao.elostupi.pt/$imageUrl';
  }

  int _getAvailableStock() {
    try {
      return Get.find<ProductController>().getAvailableStock(widget.product);
    } catch (_) {
      return widget.product.stock ?? 0;
    }
  }

  Widget _buildImageSection(
    BuildContext context,
    int stock,
    double width,
    double height,
  ) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(ProductCard.imageRadius),
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: Image.network(
              getFullImageUrl(widget.product.imageUrl),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                child: Icon(
                  Icons.image_not_supported,
                  size: 22,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ),
        ),
        if (_showFeedback && _feedbackQuantity > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(ProductCard.imageRadius),
                ),
                child: AnimatedOpacity(
                  opacity: _fadingOut ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: width,
                    height: height,
                    color: theme.colorScheme.primary,
                    alignment: Alignment.center,
                    child: Text(
                      '$_feedbackQuantity',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: _buildStockBadge(context, stock),
        ),
      ],
    );
  }

  Widget _buildStockBadge(BuildContext context, int stock) {
    if (!widget.product.manageStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade700.withValues(alpha: 0.3),
              blurRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: const Text(
          'Disponível',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
      );
    }

    final Color color = stock == 0
        ? Colors.red.shade700
        : (stock <= 5 ? Colors.orange.shade700 : Colors.green.shade700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Text(
        stock == 0 ? 'Sem stock' : '$stock',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildContentSection(
    BuildContext context,
    CartController cartController,
    AppController appController,
    double contentHeight,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(ProductCard.contentPadding),
      child: SizedBox(
        height: contentHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.product.name,
                  style:
                      theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        height: 1.15,
                      ) ??
                      TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                        height: 1.15,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.product.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.product.description,
                    style:
                        theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.15,
                        ) ??
                        TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.15,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            _buildPriceRow(context, cartController, appController),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    CartController cartController,
    AppController appController,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Obx(() {
            final displayPrice =
                appController.showResalePrice.value &&
                    widget.product.price2 != null
                ? widget.product.price2!
                : widget.product.price;
            final isResale =
                appController.showResalePrice.value &&
                widget.product.price2 != null;
            final bgColor = isResale
                ? Colors.orange.shade50
                : Colors.green.shade50;
            final borderColor = isResale
                ? Colors.orange.shade200
                : Colors.green.shade200;
            final textColor = isResale
                ? Colors.orange.shade800
                : Colors.green.shade800;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(ProductCard.buttonRadius),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                '€${displayPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ),
        const SizedBox(width: 6),
        _buildAddButton(context, cartController),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context, CartController cartController) {
    final theme = Theme.of(context);
    final hasStock = _getAvailableStock() > 0 || !widget.product.manageStock;
    if (!hasStock) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: ProductCard.minButtonHeight,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(ProductCard.buttonRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.remove_shopping_cart,
                size: 14,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                'Indisponível',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final primary = theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          debugPrint(
            '[ProductCard] addToCart: ${widget.product.id} ${widget.product.name}',
          );
          _onAddPressed(cartController);
        },
        borderRadius: BorderRadius.circular(ProductCard.buttonRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ProductCard.minButtonHeight,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(ProductCard.buttonRadius),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_shopping_cart, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Adicionar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final appController = Get.find<AppController>();
    final stock = _getAvailableStock();
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth;
        final cardH = constraints.maxHeight;
        final imageW = cardW * ProductCard.imageWidthFraction;

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(ProductCard.cardRadius),
            border: Border.all(color: theme.colorScheme.outlineVariant),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ProductCard.cardRadius),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSection(context, stock, imageW, cardH),
                Expanded(
                  child: _buildContentSection(
                    context,
                    cartController,
                    appController,
                    cardH,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
