import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/standard_appbar.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Administração',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          _buildMenuCard(
            context,
            icon: Icons.inventory,
            title: 'Gestão de Produtos',
            subtitle: 'Adicionar, editar e remover produtos da loja',
            onTap: () => Get.toNamed('/admin/products'),
          ),
          _buildMenuCard(
            context,
            icon: Icons.people,
            title: 'Gestão de Consulentes',
            subtitle: 'Registar e acompanhar consulentes e consultas',
            onTap: () => Get.toNamed('/consulentes'),
          ),
          _buildMenuCard(
            context,
            icon: Icons.checklist,
            title: 'Marcação de presenças',
            subtitle: 'Marcar presenças e faltas por data',
            onTap: () => Get.toNamed('/attendance'),
          ),
          _buildMenuCard(
            context,
            icon: Icons.electric_bolt,
            title: 'Contagem de Luz',
            subtitle: 'Registar leituras e calcular custos',
            onTap: () => Get.toNamed('/electricity'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 0)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
