import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../models/product.dart';

class PendingOrdersScreen extends StatefulWidget {
  const PendingOrdersScreen({super.key});

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  late CartController cartController;

  @override
  void initState() {
    super.initState();
    cartController = Get.find<CartController>();
    cartController.updatePendingOrders();
  }

  void refreshOrders() {
    cartController.updatePendingOrders();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos Pendentes'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        final pendingOrders = cartController.pendingOrders;
        if (cartController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (pendingOrders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.orange,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum pedido pendente',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingOrders.length,
          itemBuilder: (context, index) {
            final order = pendingOrders[index];
            final List<dynamic> items = order['items'] ?? [];
            final total = double.tryParse(order['total'].toString()) ?? 0.0;
            final createdAt = order['createdAt'] ?? '';
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.08 * 255).toInt()),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pedido #${order['id']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          createdAt.toString(),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
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
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                'x$quantity',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            'Produto inválido',
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        );
                      }
                    }),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total: €${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Finalizar'),
                            onPressed: () async {
                              final ok = await cartController.finalizePendingOrderAPI(order['id']);
                              if (ok) refreshOrders();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text('Apagar'),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remover Pedido'),
                                  content: const Text('Tem certeza que deseja remover este pedido pendente?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Remover'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await cartController.removePendingOrderAPI(order['id']);
                                refreshOrders();
                              }
                            },
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