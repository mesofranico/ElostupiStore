import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/bluetooth_print_service.dart';
import '../widgets/standard_appbar.dart';

class BluetoothPrinterScreen extends StatelessWidget {
  BluetoothPrinterScreen({super.key});

  final BluetoothPrintService _bluetoothService = Get.find<BluetoothPrintService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: 'Impressora Bluetooth',
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estado da ligação
            Obx(() => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado da Ligação',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _bluetoothService.isBluetoothOn 
                            ? (_bluetoothService.isConnected.value 
                              ? Icons.bluetooth_connected 
                              : Icons.bluetooth)
                            : Icons.bluetooth_disabled,
                          color: _bluetoothService.isBluetoothOn 
                            ? (_bluetoothService.isConnected.value 
                              ? Colors.green 
                              : Colors.blue)
                            : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _bluetoothService.isBluetoothOn 
                            ? (_bluetoothService.isConnected.value 
                              ? 'Conectado' 
                              : 'Bluetooth Ligado')
                            : 'Bluetooth Desligado',
                          style: TextStyle(
                            color: _bluetoothService.isBluetoothOn 
                              ? (_bluetoothService.isConnected.value 
                                ? Colors.green 
                                : Colors.blue)
                              : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_bluetoothService.selectedDevice.value != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Dispositivo: ${_bluetoothService.selectedDevice.value!.name.isNotEmpty ? _bluetoothService.selectedDevice.value!.name : _bluetoothService.selectedDevice.value!.address}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            )),

            const SizedBox(height: 16),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _bluetoothService.isScanning.value 
                      ? () => _bluetoothService.stopScan()
                      : () => _bluetoothService.startScan(),
                    icon: Icon(_bluetoothService.isScanning.value ? Icons.stop : Icons.search),
                    label: Obx(() => Text(
                      _bluetoothService.isScanning.value 
                        ? 'Parar Scan' 
                        : 'Procurar Dispositivos'
                    )),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _bluetoothService.isScanning.value ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _bluetoothService.isConnected.value 
                      ? () => _bluetoothService.disconnect()
                      : null,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Desligar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Teste de impressão
            ElevatedButton.icon(
              onPressed: _bluetoothService.isConnected.value 
                ? () => _bluetoothService.printTest()
                : null,
              icon: const Icon(Icons.print),
              label: const Text('Teste de Impressão'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 8),



            const SizedBox(height: 16),

            // Lista de dispositivos
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Dispositivos Encontrados',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                                         Expanded(
                       child: Obx(() {
                         if (!_bluetoothService.isBluetoothOn) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bluetooth_disabled,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Bluetooth Desligado',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Ligue o Bluetooth para procurar dispositivos',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                                                 if (_bluetoothService.devices.isEmpty) {
                           return Center(
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 const Icon(
                                   Icons.bluetooth_searching,
                                   size: 64,
                                   color: Colors.grey,
                                 ),
                                 const SizedBox(height: 16),
                                 const Text(
                                   'Nenhum dispositivo encontrado',
                                   style: TextStyle(
                                     fontSize: 18,
                                     fontWeight: FontWeight.bold,
                                     color: Colors.grey,
                                   ),
                                 ),
                                 const SizedBox(height: 8),
                                 const Text(
                                   'Toque em "Procurar Dispositivos" para começar',
                                   textAlign: TextAlign.center,
                                   style: TextStyle(
                                     color: Colors.grey,
                                     fontSize: 16,
                                   ),
                                 ),
                                 
                               ],
                             ),
                           );
                         }

                        return ListView.builder(
                          itemCount: _bluetoothService.devices.length,
                          itemBuilder: (context, index) {
                            final device = _bluetoothService.devices[index];
                            final isConnected = _bluetoothService.selectedDevice.value?.address == device.address;
                            
                                                         return ListTile(
                               leading: Icon(
                                 isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                                 color: isConnected ? Colors.green : Colors.blue,
                               ),
                               title: Text(
                                 device.name.isNotEmpty ? device.name : 'Dispositivo Desconhecido',
                                 style: TextStyle(
                                   fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                                 ),
                               ),
                                                               subtitle: Text(device.address),
                               trailing: ElevatedButton(
                                 onPressed: isConnected 
                                   ? null 
                                   : () => _bluetoothService.connectToDevice(device),
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: isConnected ? Colors.grey : Colors.blue,
                                   foregroundColor: Colors.white,
                                 ),
                                 child: Text(isConnected ? 'Conectado' : 'Ligar'),
                               ),
                             );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 