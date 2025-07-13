import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/app_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find<AppController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.refresh,
                  color: Colors.blue[600],
                  size: 24,
                ),
              ),
              title: const Text(
                'Atualização Automática',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Atualizar produtos automaticamente',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              trailing: Obx(() => Switch(
                value: appController.autoRefreshEnabled.value,
                onChanged: (value) => appController.toggleAutoRefresh(),
                activeColor: Colors.blue,
              )),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.euro,
                  color: Colors.green[600],
                  size: 24,
                ),
              ),
              title: const Text(
                'Preços de Revenda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Mostrar preços de revenda',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              trailing: Obx(() => Switch(
                value: appController.showResalePrice.value,
                onChanged: (value) => appController.toggleResalePrice(),
                activeColor: Colors.green,
              )),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.purple[600],
                  size: 24,
                ),
              ),
              title: const Text(
                'Gestão de Produtos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Adicionar, editar e remover produtos',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              onTap: () {
                Get.toNamed('/admin');
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info,
                  color: Colors.orange[600],
                  size: 24,
                ),
              ),
              title: const Text(
                'Sobre',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Versão 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              onTap: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Sobre ElosTupi'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Versão: 1.0.0'),
                        SizedBox(height: 8),
                        Text('Desenvolvido com Flutter e GetX'),
                        SizedBox(height: 8),
                        Text('Uma loja moderna e responsiva'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 