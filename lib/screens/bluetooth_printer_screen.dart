import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/bluetooth_print_service.dart';
import '../widgets/standard_appbar.dart';

class BluetoothPrinterScreen extends StatelessWidget {
  BluetoothPrinterScreen({super.key});

  final BluetoothPrintService _bluetoothService = Get.find<BluetoothPrintService>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Impressora Bluetooth',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() => _buildStatusCard(context)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _bluetoothService.isScanning.value
                        ? () => _bluetoothService.stopScan()
                        : () => _bluetoothService.startScan(),
                    icon: Icon(_bluetoothService.isScanning.value ? Icons.stop : Icons.search, size: 18),
                    label: Obx(() => Text(
                        _bluetoothService.isScanning.value ? 'Parar scan' : 'Procurar dispositivos')),
                    style: FilledButton.styleFrom(
                      backgroundColor: _bluetoothService.isScanning.value
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      foregroundColor: _bluetoothService.isScanning.value
                          ? theme.colorScheme.onError
                          : theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _bluetoothService.isConnected.value ? () => _bluetoothService.disconnect() : null,
                    icon: const Icon(Icons.bluetooth_disabled, size: 18),
                    label: const Text('Desligar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _bluetoothService.isConnected.value ? () => _bluetoothService.printTest() : null,
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Teste de impressão'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Dispositivos encontrados',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                if (!_bluetoothService.isBluetoothOn) {
                  return _buildEmptyState(
                    context,
                    icon: Icons.bluetooth_disabled,
                    title: 'Bluetooth desligado',
                    subtitle: 'Ligue o Bluetooth para procurar dispositivos',
                    color: theme.colorScheme.error,
                  );
                }
                if (_bluetoothService.devices.isEmpty) {
                  return _buildEmptyState(
                    context,
                    icon: Icons.bluetooth_searching,
                    title: 'Nenhum dispositivo encontrado',
                    subtitle: 'Toque em «Procurar dispositivos» para começar',
                    color: theme.colorScheme.outline,
                  );
                }
                return ListView.builder(
                  itemCount: _bluetoothService.devices.length,
                  itemBuilder: (context, index) {
                    final device = _bluetoothService.devices[index];
                    final isConnected =
                        _bluetoothService.selectedDevice.value?.address == device.address;
                    return _buildDeviceTile(context, device.name, device.address, isConnected, () {
                      if (!isConnected) _bluetoothService.connectToDevice(device);
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 0)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado da ligação',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _bluetoothService.isBluetoothOn
                    ? (_bluetoothService.isConnected.value ? Icons.bluetooth_connected : Icons.bluetooth)
                    : Icons.bluetooth_disabled,
                color: _bluetoothService.isBluetoothOn
                    ? (_bluetoothService.isConnected.value ? Colors.green : theme.colorScheme.primary)
                    : theme.colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                _bluetoothService.isBluetoothOn
                    ? (_bluetoothService.isConnected.value ? 'Conectado' : 'Bluetooth ligado')
                    : 'Bluetooth desligado',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _bluetoothService.isBluetoothOn
                      ? (_bluetoothService.isConnected.value ? Colors.green : theme.colorScheme.primary)
                      : theme.colorScheme.error,
                ),
              ),
            ],
          ),
          if (_bluetoothService.selectedDevice.value != null) ...[
            const SizedBox(height: 8),
            Text(
              'Dispositivo: ${_bluetoothService.selectedDevice.value!.name.isNotEmpty ? _bluetoothService.selectedDevice.value!.name : _bluetoothService.selectedDevice.value!.address}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: color == theme.colorScheme.error ? color : theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(
    BuildContext context,
    String name,
    String address,
    bool isConnected,
    VoidCallback onConnect,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: isConnected ? Colors.green : theme.colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'Dispositivo desconhecido',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isConnected ? FontWeight.w700 : FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: isConnected ? null : onConnect,
              style: FilledButton.styleFrom(
                backgroundColor: isConnected ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primary,
                foregroundColor: isConnected ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onPrimary,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isConnected ? 'Conectado' : 'Ligar'),
            ),
          ],
        ),
      ),
    );
  }
} 