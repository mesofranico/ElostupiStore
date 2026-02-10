import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';
import '../widgets/standard_appbar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppController appController = Get.find<AppController>();

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Configurações',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          _buildSwitchCard(
            context,
            icon: Icons.euro,
            title: 'Preços de revenda',
            subtitle: 'Mostrar preços de revenda',
            trailing: Obx(() => Switch(
              value: appController.showResalePrice.value,
              onChanged: (_) => appController.toggleResalePrice(),
              activeTrackColor: theme.colorScheme.primaryContainer,
              activeThumbColor: theme.colorScheme.primary,
            )),
          ),
          _buildSwitchCard(
            context,
            icon: Icons.visibility,
            title: 'Manter ecrã ligado',
            subtitle: 'Impedir que o ecrã apague',
            trailing: Obx(() => Switch(
              value: appController.keepScreenOn.value,
              onChanged: (_) => appController.toggleKeepScreenOn(),
              activeTrackColor: theme.colorScheme.primaryContainer,
              activeThumbColor: theme.colorScheme.primary,
            )),
          ),
          _buildMenuCard(
            context,
            icon: Icons.print,
            title: 'Impressora Bluetooth',
            subtitle: 'Configurar impressora para talões',
            onTap: () => Get.toNamed('/bluetooth-printer'),
          ),
          _buildMenuCard(
            context,
            icon: Icons.info,
            title: 'Sobre',
            subtitle: 'Versão 1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildCardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 0)),
      ],
    );
  }

  Widget _buildSwitchCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _buildCardDecoration(context),
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
              child: Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 24),
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
            trailing,
          ],
        ),
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
      decoration: _buildCardDecoration(context),
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
                  child: Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 24),
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
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetTheme = Theme.of(ctx);
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: sheetTheme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: sheetTheme.colorScheme.shadow.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetTheme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Text(
                          'Sobre',
                          style: sheetTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: sheetTheme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Versão: 1.0.0', style: sheetTheme.textTheme.bodyLarge),
                        const SizedBox(height: 16),
                        Text(
                          'Desenvolvido com Flutter e GetX',
                          style: sheetTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text('Uma loja moderna e responsiva', style: sheetTheme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        Divider(color: sheetTheme.colorScheme.outlineVariant),
                        const SizedBox(height: 8),
                        Text(
                          'Programador:',
                          style: sheetTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text('Carlos Santos', style: sheetTheme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text('opmeso@gmail.com', style: sheetTheme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        Text(
                          '© 2024 ElosTupi. Todos os direitos reservados.',
                          style: sheetTheme.textTheme.bodySmall?.copyWith(color: sheetTheme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Fechar',
                              style: sheetTheme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }
} 