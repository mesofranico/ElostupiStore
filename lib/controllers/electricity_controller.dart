import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/electricity_reading.dart';
import '../models/electricity_settings.dart';
import '../services/electricity_service.dart';

class ElectricityController extends GetxController {
  final RxList<ElectricityReading> readings = <ElectricityReading>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isAdding = false.obs;
  final Rx<ElectricitySettings?> settings = Rx<ElectricitySettings?>(null);

  // Controllers para os campos de entrada
  final counterController = TextEditingController(); // Mudou de kwController para counterController
  final notesController = TextEditingController();
  
  // Focus node temporário para remover foco
  final unfocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    loadSettings();
    loadReadings();
  }

  @override
  void onClose() {
    counterController.dispose();
    notesController.dispose();
    unfocusNode.dispose();
    super.onClose();
  }

  // Carregar configurações
  Future<void> loadSettings() async {
    try {
      final settingsData = await ElectricityService.getSettings();
      settings.value = settingsData;
    } catch (e) {
      // Se não conseguir carregar, usar configurações padrão
      settings.value = ElectricitySettings.defaultSettings();
    }
  }

  // Carregar todas as leituras
  Future<void> loadReadings() async {
    try {
      isLoading.value = true;
      final readingsList = await ElectricityService.getAllReadings();
      readings.assignAll(readingsList);
    } catch (e) {
      // Erro silencioso
    } finally {
      isLoading.value = false;
    }
  }

  // Adicionar nova leitura
  Future<void> addReading() async {
    if (counterController.text.isEmpty) {
      return;
    }

    if (settings.value == null) {
      return;
    }

    try {
      isAdding.value = true;
      
      final counterValue = double.parse(counterController.text);
      
      // Validar que o valor do contador seja um número inteiro
      if (counterValue != counterValue.toInt()) {
        return;
      }
      
      // Verificar se é a primeira leitura
      final isFirstReading = readings.isEmpty;
      
      // Para a primeira leitura, não calcular KW consumidos
      double kwConsumed = 0.0;
      double totalCost = 0.0;
      
      if (!isFirstReading) {
        // Calcular KW consumidos baseado na diferença com a leitura anterior
        final lastReading = readings.first; // Assumindo que está ordenado por data decrescente
        kwConsumed = counterValue - lastReading.counterValue;
        
        // Validar que o consumo seja positivo
        if (kwConsumed <= 0) {
          return;
        }
        
        final pricePerKw = settings.value!.defaultPricePerKw;
        totalCost = kwConsumed * pricePerKw;
      }
      
      final pricePerKw = settings.value!.defaultPricePerKw;
      final notes = notesController.text;

      await ElectricityService.addReading(
        counterValue: counterValue,
        kwConsumed: kwConsumed,
        pricePerKw: pricePerKw,
        totalCost: totalCost,
        notes: notes,
      );

      // Limpar campos
      counterController.clear();
      notesController.clear();

      // Recarregar lista
      await loadReadings();
      
      // Remover foco de todos os campos
      unfocusNode.requestFocus();
    } catch (e) {
      // Erro silencioso
    } finally {
      isAdding.value = false;
    }
  }

  // Excluir leitura
  Future<void> deleteReading(int id) async {
    try {
      await ElectricityService.deleteReading(id);
      await loadReadings();
    } catch (e) {
      // Erro silencioso
    }
  }

  // Calcular custo total com IVA
  double calculateTotalWithVAT(double totalCost) {
    final vatRate = settings.value?.vatRate ?? 23.0;
    return totalCost * (1 + vatRate / 100);
  }

  // Formatar data
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Formatar hora
  String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Obter o último valor do contador para mostrar como referência
  double? getLastCounterValue() {
    if (readings.isEmpty) return null;
    return readings.first.counterValue;
  }
} 