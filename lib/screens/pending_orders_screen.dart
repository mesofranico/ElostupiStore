import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../models/product.dart';
import '../widgets/standard_appbar.dart';
import '../core/utils/ui_utils.dart';
import '../widgets/loading_view.dart';

class PendingOrdersScreen extends StatefulWidget {
  const PendingOrdersScreen({super.key});

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  late CartController cartController;
  final Map<String, bool> _internalOrders = {};

  @override
  void initState() {
    super.initState();
    cartController = Get.find<CartController>();
    cartController.updatePendingOrders();
  }

  void refreshOrders() {
    _internalOrders.clear();
    cartController.updatePendingOrders();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Pagamentos pendentes',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
      ),
      body: Obx(() {
        final pendingOrders = cartController.pendingOrders;
        if (cartController.isLoading.value) {
          return const LoadingView();
        }
        if (pendingOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 56,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhum pedido pendente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Os pedidos guardados aparecem aqui',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: pendingOrders.length,
          itemBuilder: (context, index) {
            final order = pendingOrders[index];
            final orderId = order['id'];
            final List<dynamic> items = order['items'] ?? [];
            final total = double.tryParse(order['total'].toString()) ?? 0.0;
            final note = order['note']?.toString().trim();
            final isInternal = _internalOrders[orderId] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (note != null && note.isNotEmpty) ? note : 'Pedido',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      try {
                        final product = Product.fromJson(item['product']);
                        final quantity = item['quantity'] ?? 1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'x$quantity',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            'Produto inválido',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        );
                      }
                    }),
                    Divider(
                      height: 20,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '€${total.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Checkbox para Consumo Interno
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _internalOrders[orderId] = !isInternal;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: isInternal,
                                  onChanged: (v) {
                                    setState(() {
                                      _internalOrders[orderId] = v ?? false;
                                    });
                                  },
                                  activeColor: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Consumo Interno',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isInternal
                                      ? Colors.blue.shade700
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: isInternal
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              final ok = await cartController
                                  .finalizePendingOrderAPI(
                                    orderId,
                                    isInternal: isInternal,
                                  );
                              if (ok) refreshOrders();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: isInternal
                                  ? Colors.blue.shade700
                                  : null,
                              minimumSize: const Size(0, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(
                              isInternal
                                  ? Icons.home_repair_service
                                  : Icons.check_circle,
                              size: 18,
                            ),
                            label: Text(isInternal ? 'Consumir' : 'Finalizar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              UiUtils.showConfirmDialog(
                                title: 'Remover pedido',
                                message: 'Queres apagar este pedido pendente?',
                                confirmLabel: 'Apagar',
                                icon: Icons.delete_outline,
                                color: theme.colorScheme.error,
                                onConfirm: () async {
                                  await cartController.removePendingOrderAPI(
                                    orderId,
                                  );
                                  refreshOrders();
                                },
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(color: theme.colorScheme.error),
                              foregroundColor: theme.colorScheme.error,
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Apagar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
