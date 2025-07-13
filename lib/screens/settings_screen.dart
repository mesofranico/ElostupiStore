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
          Card(
            child: ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Atualização Automática'),
              subtitle: const Text('Atualizar produtos automaticamente'),
              trailing: Obx(() => Switch(
                value: appController.autoRefreshEnabled.value,
                onChanged: (value) => appController.toggleAutoRefresh(),
              )),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Sobre'),
              subtitle: const Text('Versão 1.0.0'),
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