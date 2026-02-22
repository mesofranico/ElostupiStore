import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../core/utils/ui_utils.dart';
import '../controllers/app_controller.dart';
import '../widgets/cart_item_widget.dart';
import '../widgets/standard_appbar.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static void _showGuardarPedidoBottomSheet(
    BuildContext context,
    ThemeData theme,
    TextEditingController noteController,
    CartController cartController,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.save_outlined,
                      color: Colors.orange.shade700,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Guardar pedido',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Adicione uma nota ao pedido:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 1,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Ex: Nome do consulente, observações...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.orange, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Cancelar',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final note = noteController.text.trim();
                          if (note.isEmpty) {
                            UiUtils.showError('Adicione uma nota ao pedido.');
                            return;
                          }
                          Navigator.of(ctx).pop();
                          final ok = await cartController.savePendingOrderAPI(
                            note: note,
                          );
                          if (ok) {
                            cartController.clearCart();
                            UiUtils.showSuccess(
                              'O pedido foi guardado. Pode finalizar mais tarde.',
                            );
                            Get.back();
                          } else {
                            UiUtils.showError(
                              'Não foi possível guardar o pedido. Tente novamente.',
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                'Guardar',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final CartController cartController = Get.find<CartController>();
    final TextEditingController noteController = TextEditingController();

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Carrinho',
        backgroundColor: theme.colorScheme.primary,
        actions: [
          Obx(() {
            if (cartController.totalItems > 0) {
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () {
                  UiUtils.showConfirmDialog(
                    title: 'Limpar carrinho?',
                    message: 'Remover todos os itens do carrinho?',
                    confirmLabel: 'Limpar',
                    icon: Icons.delete_sweep,
                    color: theme.colorScheme.error,
                    onConfirm: () => cartController.clearCart(),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 56,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Carrinho vazio',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adiciona produtos na Loja',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  itemCount: cartController.items.length,
                  itemBuilder: (context, index) {
                    return CartItemWidget(
                      cartItem: cartController.items[index],
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Total:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Obx(
                            () => Text(
                              '€${cartController.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Obx(() {
                      final appController = Get.find<AppController>();
                      final isResale = appController.showResalePrice.value;
                      final totalItems = cartController.totalItems;
                      final uniqueItems = cartController.items.length;
                      return Text(
                        '$totalItems ${totalItems == 1 ? 'item' : 'itens'} • ${uniqueItems == 1 ? '1 produto' : '$uniqueItems produtos'} • ${isResale ? 'Preço Corrente' : 'Preço Consulente'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // Toggle de Consumo Interno
                    Obx(
                      () => Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => cartController.isInternal.toggle(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: cartController.isInternal.value
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              border: Border.all(
                                color: cartController.isInternal.value
                                    ? Colors.blue.withValues(alpha: 0.3)
                                    : theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  cartController.isInternal.value
                                      ? Icons.home_repair_service
                                      : Icons.home_repair_service_outlined,
                                  size: 16,
                                  color: cartController.isInternal.value
                                      ? Colors.blue.shade700
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Consumo Interno (Terreiro)',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: cartController.isInternal.value
                                              ? Colors.blue.shade700
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          fontWeight:
                                              cartController.isInternal.value
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                  ),
                                ),
                                Switch(
                                  value: cartController.isInternal.value,
                                  onChanged: (v) =>
                                      cartController.isInternal.value = v,
                                  activeThumbColor: theme.primaryColor,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: cartController.isLoading.value
                                    ? null
                                    : () => _showGuardarPedidoBottomSheet(
                                        context,
                                        theme,
                                        noteController,
                                        cartController,
                                      ),
                                child: Container(
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: cartController.isLoading.value
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'A guardar...',
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.hourglass_empty,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Guardar Pedido',
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: cartController.isLoading.value
                                    ? null
                                    : () async {
                                        final success = await cartController
                                            .finalizeOrder();
                                        if (success) Get.back();
                                      },
                                child: Container(
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: cartController.isLoading.value
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'A processar...',
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.payment,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Finalizar Pedido',
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
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
                    ),
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
