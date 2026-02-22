import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:get/get.dart';
import '../models/cart_item.dart';
import '../core/utils/ui_utils.dart';

class BluetoothPrintService extends GetxService {
  final RxBool isConnected = false.obs;
  final RxBool isScanning = false.obs;
  final RxList<BluetoothDevice> devices = <BluetoothDevice>[].obs;
  final Rx<BluetoothDevice?> selectedDevice = Rx<BluetoothDevice?>(null);

  // Stream subscriptions
  late StreamSubscription<bool> _isScanningSubscription;
  late StreamSubscription<BlueState> _blueStateSubscription;
  late StreamSubscription<ConnectState> _connectStateSubscription;
  late StreamSubscription<Uint8List> _receivedDataSubscription;
  late StreamSubscription<List<BluetoothDevice>> _scanResultsSubscription;

  @override
  void onInit() {
    super.onInit();
    _initBluetooth();
  }

  void _initBluetooth() {
    // Listen to scan results
    _scanResultsSubscription = BluetoothPrintPlus.scanResults.listen((event) {
      if (kDebugMode) {
        print('********** scan results: ${event.length} devices **********');
      }
      for (final device in event) {
        if (kDebugMode) {
          print('Device: ${device.name} - ${device.address}');
        }
      }
      devices.clear();
      devices.addAll(event);
      if (kDebugMode) {
        print(
          '********** devices list updated: ${devices.length} devices **********',
        );
      }
    });

    // Listen to scanning state
    _isScanningSubscription = BluetoothPrintPlus.isScanning.listen((event) {
      if (kDebugMode) {
        print('********** Scanning state changed: $event **********');
      }
      isScanning.value = event;
    });

    // Listen to Bluetooth state
    _blueStateSubscription = BluetoothPrintPlus.blueState.listen((event) {
      if (kDebugMode) {
        print('********** Bluetooth state changed: $event **********');
      }
      // Handle Bluetooth state changes
    });

    // Listen to connection state
    _connectStateSubscription = BluetoothPrintPlus.connectState.listen((event) {
      switch (event) {
        case ConnectState.connected:
          isConnected.value = true;
          break;
        case ConnectState.disconnected:
          isConnected.value = false;
          selectedDevice.value = null;
          break;
      }
    });

    // Listen to received data
    _receivedDataSubscription = BluetoothPrintPlus.receivedData.listen((data) {
      // Handle received data if needed
    });
  }

  @override
  void onClose() {
    _isScanningSubscription.cancel();
    _blueStateSubscription.cancel();
    _connectStateSubscription.cancel();
    _receivedDataSubscription.cancel();
    _scanResultsSubscription.cancel();
    super.onClose();
  }

  // Iniciar scan de dispositivos
  Future<void> startScan() async {
    try {
      if (kDebugMode) {
        print('********** Starting Bluetooth scan **********');
      }
      devices.clear();
      await BluetoothPrintPlus.startScan(timeout: const Duration(seconds: 15));
      if (kDebugMode) {
        print('********** Bluetooth scan started **********');
      }
    } catch (e) {
      if (kDebugMode) {
        print('********** Error starting scan: $e **********');
      }
      UiUtils.showError('Erro ao procurar dispositivos Bluetooth');
    }
  }

  // Parar scan
  Future<void> stopScan() async {
    try {
      BluetoothPrintPlus.stopScan();
    } catch (e) {
      // Silently handle stop scan errors
    }
  }

  // Conectar a um dispositivo
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      selectedDevice.value = device;
      await BluetoothPrintPlus.connect(device);

      UiUtils.showSuccess(
        'Ligado a ${device.name.isNotEmpty ? device.name : device.address}',
      );

      return true;
    } catch (e) {
      selectedDevice.value = null;
      UiUtils.showError('Não foi possível ligar ao dispositivo');
      return false;
    }
  }

  // Desconectar
  Future<void> disconnect() async {
    try {
      await BluetoothPrintPlus.disconnect();
      selectedDevice.value = null;

      UiUtils.showInfo('Dispositivo desligado');
    } catch (e) {
      // Silently handle disconnect errors
    }
  }

  // Imprimir talão de compra usando texto simples
  Future<bool> printReceipt({
    required List<CartItem> items,
    required double total,
    String? note,
  }) async {
    if (!isConnected.value) {
      UiUtils.showError('Ligue primeiro a uma impressora Bluetooth');
      return false;
    }

    try {
      // Criar texto do talão
      final StringBuffer receipt = StringBuffer();

      // Cabeçalho centralizado
      receipt.writeln('        ELOSTUPI STORE');
      receipt.writeln('================================');

      // Informações da loja
      receipt.writeln('Velas e Artigos Religiosos');
      receipt.writeln('');

      // Data e hora formatadas
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      receipt.writeln('Data: $dateStr    Hora: $timeStr');
      receipt.writeln('--------------------------------');

      // Itens organizados
      for (final item in items) {
        final cleanName = _cleanText(item.product.name);
        final price = item.product.price.toStringAsFixed(2);
        final lineTotal = (item.product.price * item.quantity).toStringAsFixed(
          2,
        );

        // Primeira linha: Nome do produto
        receipt.writeln(cleanName);

        // Segunda linha: Quantidade, preço unitário e total
        receipt.writeln('${item.quantity}x $price EUR = $lineTotal EUR');
        receipt.writeln('');
      }

      receipt.writeln('--------------------------------');

      // Total formatado
      final totalStr = total.toStringAsFixed(2);
      receipt.writeln('TOTAL: ${' '.padLeft(15)}$totalStr EUR');

      // Nota (se houver)
      if (note != null && note.trim().isNotEmpty) {
        receipt.writeln('--------------------------------');
        receipt.writeln('NOTA:');
        final cleanNote = _cleanText(note.trim());
        // Quebrar nota em linhas de 32 caracteres
        for (int i = 0; i < cleanNote.length; i += 32) {
          final end = (i + 32 < cleanNote.length) ? i + 32 : cleanNote.length;
          receipt.writeln(cleanNote.substring(i, end));
        }
      }

      receipt.writeln('================================');
      receipt.writeln('        OBRIGADO PELA COMPRA!');
      receipt.writeln('        Volte sempre!');
      receipt.writeln('');
      receipt.writeln('ElosTupi - Qualidade e Tradicao');
      receipt.writeln('');
      receipt.writeln('');

      // Converter para bytes e imprimir (usar Latin-1 para compatibilidade)
      final receiptText = receipt.toString();
      final bytes = receiptText.codeUnits;
      await BluetoothPrintPlus.write(Uint8List.fromList(bytes));

      UiUtils.showSuccess('Talão enviado para impressora com sucesso');

      return true;
    } catch (e) {
      UiUtils.showError('Erro ao imprimir talão');
      return false;
    }
  }

  // Imprimir teste
  Future<bool> printTest() async {
    if (!isConnected.value) {
      UiUtils.showError('Ligue primeiro a uma impressora Bluetooth');
      return false;
    }

    try {
      final StringBuffer testText = StringBuffer();
      testText.writeln('TESTE DE IMPRESSAO');
      testText.writeln('================');
      testText.writeln('ElosTupi Store');
      testText.writeln('Teste de impressora Bluetooth');
      testText.writeln(DateTime.now().toString());
      testText.writeln('================');
      testText.writeln('');
      testText.writeln('');

      // Criar talão de exemplo completo com nova formatação
      testText.writeln('        ELOSTUPI STORE');
      testText.writeln('================================');
      testText.writeln('Velas e Artigos Religiosos');
      testText.writeln('');

      // Data e hora de exemplo
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      testText.writeln('Data: $dateStr    Hora: $timeStr');
      testText.writeln('--------------------------------');

      // Itens de exemplo organizados
      testText.writeln('Vela 7 Dias - Amarela');
      testText.writeln('2x 5.50 EUR = 11.00 EUR');
      testText.writeln('');

      testText.writeln('Velas Violeta / Lilas');
      testText.writeln('1x 3.25 EUR = 3.25 EUR');
      testText.writeln('');

      testText.writeln('Velas Azuis');
      testText.writeln('3x 2.75 EUR = 8.25 EUR');
      testText.writeln('');

      testText.writeln('Velas Azul-Claro');
      testText.writeln('1x 4.00 EUR = 4.00 EUR');
      testText.writeln('');

      testText.writeln('Velas Castanhas');
      testText.writeln('2x 6.50 EUR = 13.00 EUR');
      testText.writeln('');

      testText.writeln('Velas de Mel');
      testText.writeln('1x 8.75 EUR = 8.75 EUR');
      testText.writeln('');

      testText.writeln('Velas Brancas');
      testText.writeln('4x 1.50 EUR = 6.00 EUR');
      testText.writeln('');

      testText.writeln('Velas Pretas');
      testText.writeln('2x 2.00 EUR = 4.00 EUR');
      testText.writeln('');

      testText.writeln('Velas Laranja');
      testText.writeln('1x 3.75 EUR = 3.75 EUR');
      testText.writeln('');

      testText.writeln('Velas Rosa');
      testText.writeln('3x 2.25 EUR = 6.75 EUR');
      testText.writeln('');

      testText.writeln('--------------------------------');
      testText.writeln('TOTAL:               68.75 EUR');

      // Nota de exemplo
      testText.writeln('--------------------------------');
      testText.writeln('NOTA:');
      testText.writeln('Pedido para entrega amanha');
      testText.writeln('Cliente: Maria Silva');
      testText.writeln('Telefone: 912345678');

      testText.writeln('================================');
      testText.writeln('        OBRIGADO PELA COMPRA!');
      testText.writeln('        Volte sempre!');
      testText.writeln('');
      testText.writeln('ElosTupi - Qualidade e Tradicao');
      testText.writeln('');
      testText.writeln('');

      // Converter para bytes e imprimir (usar Latin-1 para compatibilidade)
      final testTextString = testText.toString();
      final bytes = testTextString.codeUnits;
      await BluetoothPrintPlus.write(Uint8List.fromList(bytes));

      UiUtils.showSuccess('Talão de exemplo enviado para impressora');

      return true;
    } catch (e) {
      UiUtils.showError('Erro ao imprimir teste');
      return false;
    }
  }

  // Verificar se Bluetooth está ligado
  bool get isBluetoothOn {
    final isOn = BluetoothPrintPlus.isBlueOn;
    if (kDebugMode) {
      print('********** Bluetooth is on: $isOn **********');
    }
    return isOn;
  }

  // Verificar se está a fazer scan
  bool get isCurrentlyScanning => BluetoothPrintPlus.isScanningNow;

  // Verificar se está conectado
  bool get isCurrentlyConnected => BluetoothPrintPlus.isConnected;

  // Limpar texto de caracteres especiais para compatibilidade com impressora
  String _cleanText(String text) {
    String result = text;

    // Substituir acentos portugueses
    result = result
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n');

    // Remover caracteres especiais europeus
    result = result
        .replaceAll('š', 's')
        .replaceAll('ž', 'z')
        .replaceAll('ć', 'c')
        .replaceAll('č', 'c')
        .replaceAll('đ', 'd')
        .replaceAll('ł', 'l')
        .replaceAll('ń', 'n')
        .replaceAll('ś', 's')
        .replaceAll('ź', 'z')
        .replaceAll('ż', 'z')
        .replaceAll('ą', 'a')
        .replaceAll('ę', 'e');

    // Remover caracteres chineses e outros problemáticos
    result = result.replaceAll('醬', '');

    // Substituir símbolos de moeda
    result = result
        .replaceAll('€', 'EUR')
        .replaceAll('£', 'GBP')
        .replaceAll('\$', 'USD');

    // Remover qualquer carácter que não seja ASCII básico
    result = result.replaceAll(RegExp(r'[^\x20-\x7E]'), '');

    // Limpar espaços extras
    result = result.trim();

    return result;
  }
}
