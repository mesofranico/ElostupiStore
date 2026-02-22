import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/recado_controller.dart';
import '../core/currency_formatter.dart';
import '../core/app_style.dart';
import '../widgets/standard_appbar.dart';
import '../core/utils/ui_utils.dart';
import 'pending_orders_screen.dart';
import 'shop_screen.dart';
import '../widgets/loading_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.put(DashboardController());
    final cartController = Get.find<CartController>();
    final productController = Get.find<ProductController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Associação Elos de Tupinambá',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => dashboardController.loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Obx(() {
            if (dashboardController.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.only(top: 48),
                child: LoadingView(),
              );
            }
            return UiUtils.animatedFadeIn(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SectionCard(
                          icon: Icons.pending_actions_outlined,
                          title: 'Pagamentos pendentes',
                          count: cartController.pendingOrders.length,
                          onTap: () =>
                              Get.to(() => const PendingOrdersScreen()),
                          child: cartController.pendingOrders.isEmpty
                              ? _emptyState(
                                  theme,
                                  Icons.inbox_outlined,
                                  'Nenhum pedido',
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: cartController.pendingOrders.map((
                                    order,
                                  ) {
                                    final total =
                                        double.tryParse(
                                          order['total'].toString(),
                                        ) ??
                                        0.0;
                                    final nota = order['note']
                                        ?.toString()
                                        .trim();
                                    return _ListItem(
                                      leading: (nota != null && nota.isNotEmpty)
                                          ? nota
                                          : '—',
                                      primary: CurrencyFormatter.formatEuro(
                                        total,
                                      ),
                                      alignPrimaryRight: true,
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SectionCard(
                          icon: Icons.warning_amber_outlined,
                          title: 'Mensalidades em atraso',
                          count: dashboardController.overdueMembers.length,
                          accent: dashboardController.overdueMembers.isNotEmpty,
                          onTap: () => Get.toNamed('/membership'),
                          child: dashboardController.overdueMembers.isEmpty
                              ? _emptyState(
                                  theme,
                                  Icons.people_outline,
                                  'Nenhuma em atraso',
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: dashboardController.overdueMembers.map((
                                    m,
                                  ) {
                                    final months = m.overdueMonths ?? 0;
                                    final total = m.totalOverdue ?? 0.0;
                                    return _ListItem(
                                      leading: m.name,
                                      primary:
                                          '$months mens. · ${CurrencyFormatter.formatEuro(total)}',
                                      alignPrimaryRight: true,
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Obx(() {
                          final _ = productController.products;
                          final lowStock = productController
                              .getLowStockProducts('Todas');
                          return _SectionCard(
                            icon: Icons.inventory_2_outlined,
                            title: 'Stock baixo',
                            count: lowStock.length,
                            accent: lowStock.isNotEmpty,
                            onTap: () => Get.to(() => const ShopScreen()),
                            child: lowStock.isEmpty
                                ? _emptyState(
                                    theme,
                                    Icons.inventory_2_outlined,
                                    'Nenhum',
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: lowStock.map((p) {
                                      final stock = productController
                                          .getAvailableStock(p);
                                      return _ListItem(
                                        leading: p.name,
                                        primary: 'Stock: $stock',
                                        accent: true,
                                        alignPrimaryRight: true,
                                      );
                                    }).toList(),
                                  ),
                          );
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SectionCard(
                          icon: Icons.bolt_outlined,
                          title: 'Última contagem',
                          count: dashboardController.lastReading.value == null
                              ? 0
                              : 1,
                          onTap: () => Get.toNamed('/electricity'),
                          child: dashboardController.lastReading.value == null
                              ? _emptyState(
                                  theme,
                                  Icons.bolt_outlined,
                                  'Sem leitura',
                                )
                              : _ListItem(
                                  leading:
                                      '${dashboardController.lastReading.value!.counterValue.toInt()} kWh',
                                  primary: _formatDate(
                                    dashboardController
                                        .lastReading
                                        .value!
                                        .readingDate,
                                  ),
                                  highlight: true,
                                  alignPrimaryRight: true,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() {
                          final recadoController = Get.find<RecadoController>();
                          final list = recadoController.recados;
                          final temAlerta =
                              recadoController.comAlerta.isNotEmpty;
                          return _SectionCard(
                            icon: Icons.note_alt_outlined,
                            title: 'Recados e avisos',
                            count: list.length,
                            accent: temAlerta,
                            accentColor: theme.colorScheme.tertiary,
                            onTap: () => Get.toNamed('/recados'),
                            child: list.isEmpty
                                ? _emptyState(
                                    theme,
                                    Icons.note_add_outlined,
                                    'Nenhum recado',
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: list.map((r) {
                                      final dias = r.diasRestantes;
                                      String? trailing;
                                      if (r.dataLimite != null ||
                                          dias != null) {
                                        final dataStr = r.dataLimite != null
                                            ? _formatDate(r.dataLimite!)
                                            : null;
                                        final diasStr = dias != null
                                            ? (dias == 1
                                                  ? '1 dia restante'
                                                  : '$dias dias restantes')
                                            : null;
                                        trailing = [
                                          if (dataStr != null) dataStr,
                                          if (diasStr != null) diasStr,
                                        ].join(' · ');
                                      }
                                      return _RecadoListItem(
                                        text: r.titulo,
                                        trailing: trailing,
                                        accent:
                                            r.alerta ||
                                            (dias != null && dias <= 7),
                                        accentColor: theme.colorScheme.tertiary,
                                      );
                                    }).toList(),
                                  ),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _SectionCard extends StatelessWidget {
  static const double _listMaxHeight = 140;
  final IconData icon;
  final String title;
  final int count;
  final bool accent;
  final Color? accentColor;
  final VoidCallback onTap;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.count,
    this.accent = false,
    this.accentColor,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccent = accent ? (accentColor ?? AppStyle.accent) : null;

    // Icon colors
    final iconBg = effectiveAccent != null
        ? effectiveAccent.withValues(alpha: 0.15)
        : AppStyle.primary.withValues(alpha: 0.1);
    final iconFg = effectiveAccent ?? AppStyle.primary;

    // Badge colors
    final badgeBg = effectiveAccent ?? AppStyle.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (effectiveAccent ?? Colors.black).withValues(
                    alpha: 0.05,
                  ),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: (effectiveAccent ?? Colors.black).withValues(
                  alpha: 0.05,
                ),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: iconFg),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: _listMaxHeight,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0.8, 1.0],
                      ).createShader(bounds);
                    },
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: child,
                    ),
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

class _RecadoListItem extends StatelessWidget {
  final String text;
  final String? trailing;
  final bool accent;
  final Color accentColor;

  const _RecadoListItem({
    required this.text,
    this.trailing,
    this.accent = false,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = accent
        ? accentColor.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: accent ? accentColor : theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
            ),
          ),
          if (trailing != null && trailing!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: accent
                    ? accentColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String leading;
  final String primary;
  final bool accent;
  final bool highlight;
  final bool alignPrimaryRight;

  const _ListItem({
    required this.leading,
    required this.primary,
    this.accent = false,
    this.highlight = false,
    this.alignPrimaryRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = accent
        ? AppStyle.danger.withValues(alpha: 0.05)
        : (highlight
              ? AppStyle.primary.withValues(alpha: 0.08)
              : const Color(0xFFF1F5F9));

    final textColor = accent ? AppStyle.danger : const Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: AppStyle.primary.withValues(alpha: 0.2))
            : Border.all(color: Colors.black.withValues(alpha: 0.03), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              leading,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          alignPrimaryRight
              ? Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      primary,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              : Flexible(
                  child: Text(
                    primary,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
        ],
      ),
    );
  }
}
