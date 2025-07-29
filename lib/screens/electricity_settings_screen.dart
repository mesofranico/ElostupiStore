import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/electricity_controller.dart';
import '../services/electricity_service.dart';
import '../core/currency_formatter.dart';

class ElectricitySettingsScreen extends StatelessWidget {
  const ElectricitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ElectricityController controller = Get.find<ElectricityController>();
    
    // Controllers para os campos de configuração
    final priceController = TextEditingController();
    final vatController = TextEditingController();

    // Preencher campos com valores atuais
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.settings.value != null) {
        priceController.text = controller.settings.value!.defaultPricePerKw.toStringAsFixed(4);
        vatController.text = controller.settings.value!.vatRate.toStringAsFixed(1);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações de Eletricidade'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: Colors.orange[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configurações Padrão',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Defina os valores padrão para preço por KW e IVA',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Formulário de configurações
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Valores Padrão',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Campo Preço por KW
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Preço por KW (€)',
                      hintText: 'Ex: 0.1500',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.euro, color: Colors.orange),
                      helperText: 'Preço padrão por quilowatt-hora',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Campo IVA
                  TextField(
                    controller: vatController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Taxa de IVA (%)',
                      hintText: 'Ex: 23.0',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent, color: Colors.orange),
                      helperText: 'Taxa de IVA aplicada aos custos',
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botão Salvar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final price = double.parse(priceController.text);
                          final vat = double.parse(vatController.text);
                          
                          if (price < 0 || vat < 0) {
                            Get.snackbar(
                              'Erro',
                              'Os valores devem ser positivos',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red[100],
                              colorText: Colors.red[900],
                            );
                            return;
                          }
                          
                          await ElectricityService.updateSettings(
                            defaultPricePerKw: price,
                            vatRate: vat,
                          );
                          
                          await controller.loadSettings();
                          
                          Get.snackbar(
                            'Sucesso',
                            'Configurações atualizadas com sucesso!',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green[100],
                            colorText: Colors.green[900],
                          );
                          
                          Get.back();
                        } catch (e) {
                          Get.snackbar(
                            'Erro',
                            'Falha ao atualizar configurações: $e',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red[100],
                            colorText: Colors.red[900],
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Salvar Configurações',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Informações atuais
            Obx(() {
              if (controller.settings.value == null) {
                return const SizedBox.shrink();
              }
              
              final settings = controller.settings.value!;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configurações Atuais',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Preço/KW',
                            CurrencyFormatter.formatEuroWithSeparator(settings.defaultPricePerKw),
                            Icons.euro,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'IVA',
                            '${settings.vatRate.toStringAsFixed(1)}%',
                            Icons.percent,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Última atualização: ${_formatDate(settings.updatedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 