import 'package:flutter/material.dart';
import '../models/product.dart';
import 'action_badge.dart';

class ProductActions extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductActions({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionBadge(
          icon: Icons.edit,
          label: 'Editar',
          color: Colors.blue,
          onPressed: onEdit,
        ),
        const SizedBox(width: 12),
        ActionBadge(
          icon: Icons.delete,
          label: 'Remover',
          color: Colors.red,
          onPressed: onDelete,
        ),
      ],
    );
  }
} 