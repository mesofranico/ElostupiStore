import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/electricity_controller.dart';
import '../core/currency_formatter.dart';
import '../widgets/standard_appbar.dart';

class ElectricityReadingScreen extends StatelessWidget {
  const ElectricityReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ElectricityController controller = Get.put(ElectricityController());

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Contagem de Luz',
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/electricity/settings'),
            tooltip: 'Configurações',
          ),
        ],
      ),
             body: Column(
         children: [
           // Focus node invisível para remover foco
           Focus(
             focusNode: controller.unfocusNode,
             child: const SizedBox.shrink(),
           ),
                     // Formulário para adicionar nova leitura
           Container(
             margin: const EdgeInsets.all(16),
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(20),
               boxShadow: [
                 BoxShadow(
                   color: Colors.grey.withValues(alpha: 0.08),
                   blurRadius: 12,
                   offset: const Offset(0, 4),
                   spreadRadius: 0,
                 ),
               ],
             ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                 Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         gradient: LinearGradient(
                           colors: [Colors.orange[400]!, Colors.orange[600]!],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                         ),
                         borderRadius: BorderRadius.circular(10),
                       ),
                       child: const Icon(
                         Icons.add_circle_outline,
                         color: Colors.white,
                         size: 20,
                       ),
                     ),
                     const SizedBox(width: 12),
                     const Text(
                       'Nova Leitura',
                       style: TextStyle(
                         fontSize: 20,
                         fontWeight: FontWeight.bold,
                         color: Colors.orange,
                       ),
                     ),
                   ],
                 ),
                const SizedBox(height: 16),
                
                                 // Campo Valor do Contador
                 TextField(
                   controller: controller.counterController,
                   keyboardType: TextInputType.number,
                   decoration: InputDecoration(
                     labelText: 'Valor do Contador',
                     hintText: 'Ex: 1500',
                     border: const OutlineInputBorder(),
                     prefixIcon: const Icon(Icons.electric_bolt, color: Colors.orange),
                     helperText: controller.readings.isEmpty 
                         ? 'Primeira leitura - valor inicial do contador'
                         : 'Apenas números inteiros',
                     suffixIcon: controller.getLastCounterValue() != null
                         ? Container(
                             margin: const EdgeInsets.all(8),
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                               color: Colors.blue[50],
                               borderRadius: BorderRadius.circular(6),
                               border: Border.all(color: Colors.blue[200]!),
                             ),
                             child: Text(
                               'Último: ${controller.getLastCounterValue()!.toInt()}',
                               style: TextStyle(
                                 fontSize: 12,
                                 color: Colors.blue[700],
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           )
                         : null,
                   ),
                 ),
                
                const SizedBox(height: 12),
                
                                 // Informação do preço atual
                 Obx(() {
                   if (controller.settings.value != null) {
                     return Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         gradient: LinearGradient(
                           colors: [Colors.green[50]!, Colors.green[100]!],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                         ),
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.green[200]!),
                       ),
                       child: Row(
                         children: [
                           Container(
                             padding: const EdgeInsets.all(6),
                             decoration: BoxDecoration(
                               color: Colors.green[600],
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: const Icon(
                               Icons.euro,
                               color: Colors.white,
                               size: 16,
                             ),
                           ),
                           const SizedBox(width: 10),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   'Preço Atual por KW',
                                   style: TextStyle(
                                     fontSize: 12,
                                     color: Colors.green[700],
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                                 Text(
                                   CurrencyFormatter.formatEuroWithSeparator(controller.settings.value!.defaultPricePerKw),
                                   style: TextStyle(
                                     fontSize: 16,
                                     color: Colors.green[800],
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         ],
                       ),
                     );
                   }
                   return const SizedBox.shrink();
                 }),
                
                const SizedBox(height: 12),
                
                // Campo Observações
                TextField(
                  controller: controller.notesController,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                    hintText: 'Adicione observações sobre a leitura',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note, color: Colors.orange),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                                 // Botão Adicionar
                 SizedBox(
                   width: double.infinity,
                   child: Obx(() => ElevatedButton(
                     onPressed: controller.isAdding.value ? null : controller.addReading,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.orange,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 14),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                       elevation: 2,
                     ),
                     child: controller.isAdding.value
                         ? const SizedBox(
                             height: 20,
                             width: 20,
                             child: CircularProgressIndicator(
                               strokeWidth: 2,
                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                             ),
                           )
                         : Row(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               const Icon(
                                 Icons.add_circle,
                                 size: 20,
                               ),
                               const SizedBox(width: 8),
                               const Text(
                                 'Adicionar Leitura',
                                 style: TextStyle(
                                   fontSize: 16,
                                   fontWeight: FontWeight.w600,
                                 ),
                               ),
                             ],
                           ),
                   )),
                 ),
              ],
            ),
          ),
          
          // Lista de leituras
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                );
              }
              
              if (controller.readings.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.electric_bolt_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhuma leitura registada',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.readings.length,
                itemBuilder: (context, index) {
                  final reading = controller.readings[index];
                  final totalWithVAT = controller.calculateTotalWithVAT(reading.totalCost);
                  
                                     return GestureDetector(
                     onDoubleTap: () => _showDeleteDialog(context, controller, reading.id),
                     child: Container(
                       margin: const EdgeInsets.only(bottom: 8),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(10),
                         boxShadow: [
                           BoxShadow(
                             color: Colors.grey.withValues(alpha: 0.08),
                             blurRadius: 3,
                             offset: const Offset(0, 1),
                           ),
                         ],
                       ),
                       child: Padding(
                         padding: const EdgeInsets.all(12),
                         child: Row(
                           children: [
                             // Ícone compacto
                             Container(
                               width: 36,
                               height: 36,
                               decoration: BoxDecoration(
                                 gradient: LinearGradient(
                                   colors: [Colors.orange[400]!, Colors.orange[600]!],
                                   begin: Alignment.topLeft,
                                   end: Alignment.bottomRight,
                                 ),
                                 borderRadius: BorderRadius.circular(8),
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.orange.withValues(alpha: 0.2),
                                     blurRadius: 3,
                                     offset: const Offset(0, 1),
                                   ),
                                 ],
                               ),
                               child: const Icon(
                                 Icons.electric_bolt,
                                 color: Colors.white,
                                 size: 16,
                               ),
                             ),
                             const SizedBox(width: 12),
                             
                             // Conteúdo compacto
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   // Linha principal: KW, preço e data
                                   Row(
                                     children: [
                                       // KW
                                       Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                         decoration: BoxDecoration(
                                           color: reading.kwConsumed == 0 
                                               ? Colors.grey[50]
                                               : Colors.blue[50],
                                           borderRadius: BorderRadius.circular(4),
                                           border: Border.all(color: reading.kwConsumed == 0 
                                               ? Colors.grey[200]!
                                               : Colors.blue[200]!),
                                         ),
                                         child: Text(
                                           reading.kwConsumed == 0 
                                               ? 'Inicial'
                                               : '${reading.kwConsumed.toInt()} KW',
                                           style: TextStyle(
                                             fontSize: 13,
                                             fontWeight: FontWeight.bold,
                                             color: reading.kwConsumed == 0 
                                                 ? Colors.grey[600]
                                                 : Colors.blue[700],
                                           ),
                                         ),
                                       ),
                                       const SizedBox(width: 8),
                                       // Preço total
                                       Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                         decoration: BoxDecoration(
                                           color: reading.kwConsumed == 0 
                                               ? Colors.grey[50]
                                               : Colors.green[50],
                                           borderRadius: BorderRadius.circular(4),
                                           border: Border.all(color: reading.kwConsumed == 0 
                                               ? Colors.grey[200]!
                                               : Colors.green[200]!),
                                         ),
                                         child: Text(
                                           reading.kwConsumed == 0 
                                               ? '€0.00'
                                               : CurrencyFormatter.formatEuroWithSeparator(totalWithVAT),
                                           style: TextStyle(
                                             fontSize: 13,
                                             fontWeight: FontWeight.bold,
                                             color: reading.kwConsumed == 0 
                                               ? Colors.grey[600]
                                               : Colors.green[700],
                                           ),
                                         ),
                                       ),
                                       const Spacer(),
                                       // Data compacta
                                       Text(
                                         controller.formatDate(reading.readingDate),
                                         style: TextStyle(
                                           fontSize: 11,
                                           color: Colors.grey[500],
                                           fontWeight: FontWeight.w500,
                                         ),
                                       ),
                                     ],
                                   ),
                                   
                                   const SizedBox(height: 4),
                                   
                                   // Linha secundária: detalhes e observações
                                   Row(
                                     children: [
                                       // Preço/KW
                                       Icon(
                                         Icons.euro,
                                         size: 10,
                                         color: Colors.grey[500],
                                       ),
                                       const SizedBox(width: 2),
                                       Text(
                                         '${CurrencyFormatter.formatEuroWithSeparator(reading.pricePerKw)}/KW',
                                         style: TextStyle(
                                           fontSize: 10,
                                           color: Colors.grey[600],
                                           fontWeight: FontWeight.w500,
                                         ),
                                       ),
                                       const SizedBox(width: 8),
                                       // IVA
                                       Icon(
                                         Icons.receipt,
                                         size: 10,
                                         color: Colors.grey[500],
                                       ),
                                       const SizedBox(width: 2),
                                       Text(
                                         'IVA ${controller.settings.value?.vatRate.toStringAsFixed(1) ?? '23.0'}%',
                                         style: TextStyle(
                                           fontSize: 10,
                                           color: Colors.grey[600],
                                           fontWeight: FontWeight.w500,
                                         ),
                                       ),
                                       const Spacer(),
                                       // Hora
                                       Text(
                                         controller.formatTime(reading.readingDate),
                                         style: TextStyle(
                                           fontSize: 10,
                                           color: Colors.grey[400],
                                         ),
                                       ),
                                     ],
                                   ),
                                   
                                   // Observações (se houver) - linha única
                                   if (reading.notes.isNotEmpty) ...[
                                     const SizedBox(height: 2),
                                     Row(
                                       children: [
                                         Icon(
                                           Icons.note,
                                           size: 10,
                                           color: Colors.grey[400],
                                         ),
                                         const SizedBox(width: 2),
                                         Expanded(
                                           child: Text(
                                             reading.notes,
                                             style: TextStyle(
                                               fontSize: 10,
                                               color: Colors.grey[500],
                                               fontStyle: FontStyle.italic,
                                             ),
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ],
                                   
                                   // Indicador discreto de duplo toque
                                   const SizedBox(height: 2),
                                   Align(
                                     alignment: Alignment.centerRight,
                                     child: Text(
                                       'Duplo toque para excluir',
                                       style: TextStyle(
                                         fontSize: 8,
                                         color: Colors.grey[300],
                                         fontStyle: FontStyle.italic,
                                       ),
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                   );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ElectricityController controller, int id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta leitura?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteReading(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
} 