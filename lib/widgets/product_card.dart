import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../controllers/cart_controller.dart';
import '../controllers/app_controller.dart';
import '../controllers/product_controller.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  // Calcula o tamanho da fonte baseado no tamanho da tela
  double _getFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      return 18; // Desktop grande
    } else if (screenWidth >= 900) {
      return 17; // Desktop pequeno / Tablet grande
    } else if (screenWidth >= 600) {
      return 16; // Tablet
    } else {
      return 16; // Smartphone
    }
  }

  // Calcula o tamanho da fonte do preço baseado no tamanho da tela
  double _getPriceFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= 1200) {
      return 20; // Desktop grande
    } else if (screenWidth >= 900) {
      return 19; // Desktop pequeno / Tablet grande
    } else if (screenWidth >= 600) {
      return 18; // Tablet
    } else {
      return 18; // Smartphone
    }
  }

  // Função utilitária para montar a URL completa da imagem
  String getFullImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    return 'https://elostupi.csmpanel.ovh/$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();
    final AppController appController = Get.find<AppController>();
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem do produto
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          getFullImageUrl(product.imageUrl),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      // Indicador de stock no canto superior direito
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Builder(
                          builder: (context) {
                            try {
                              final productController = Get.find<ProductController>();
                              final availableStock = productController.getAvailableStock(product);
                              
                              if (availableStock == 0) {
                                // Sem stock
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Sem Stock',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              } else if (availableStock <= 5) {
                                // Stock baixo
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Stock: $availableStock',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              } else {
                                // Stock normal
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Stock: $availableStock',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              // Fallback se ProductController não estiver disponível
                              final stock = product.stock ?? 0;
                              
                              if (stock == 0) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Sem Stock',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              } else if (stock <= 5) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Stock: $stock',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              } else {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Stock: $stock',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      // Overlay gradiente sutil
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Informações do produto
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nome do produto
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: _getFontSize(context) - 1,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Descrição do produto
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Separador visual
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey[200]!,
                            Colors.grey[300]!,
                            Colors.grey[200]!,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Preço e botão
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Preço
                          Flexible(
                            child: Obx(() {
                              final displayPrice = appController.showResalePrice.value && product.price2 != null 
                                  ? product.price2! 
                                  : product.price;
                              final isResalePrice = appController.showResalePrice.value && product.price2 != null;
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isResalePrice ? Colors.orange[50] : Colors.green[50],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isResalePrice ? Colors.orange[200]! : Colors.green[200]!,
                                  ),
                                ),
                                child: Text(
                                  '€${displayPrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: _getPriceFontSize(context) - 3,
                                    fontWeight: FontWeight.bold,
                                    color: isResalePrice ? Colors.orange[700] : Colors.green[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          // Botão adicionar
                          Builder(
                            builder: (context) {
                              try {
                                final productController = Get.find<ProductController>();
                                final availableStock = productController.getAvailableStock(product);
                                final hasStock = availableStock > 0;
                                
                                if (!hasStock) {
                                  // Produto sem stock - botão desabilitado
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.remove_shopping_cart,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Indisponível',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  // Produto com stock - botão normal
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          cartController.addToCart(product);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.add_shopping_cart,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Adicionar',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
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
                              } catch (e) {
                                // Fallback se ProductController não estiver disponível
                                final hasStock = (product.stock ?? 0) > 0;
                                
                                if (!hasStock) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.remove_shopping_cart,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Indisponível',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          cartController.addToCart(product);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.add_shopping_cart,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Adicionar',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
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
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 