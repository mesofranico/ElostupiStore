import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/consulente_controller.dart';
import '../models/consulente.dart';
import '../models/consulente_session.dart';
import '../widgets/standard_appbar.dart';
import 'consulente_form_screen.dart';
import 'consulente_detail_screen.dart';

class ConsulentesScreen extends StatelessWidget {
  const ConsulentesScreen({super.key});

  Future<Map<String, dynamic>> _getConsulenteData(int consulenteId, ConsulentesController controller) async {
    final sessionCount = await controller.getSessionCount(consulenteId);
    final lastSession = await controller.getLastSession(consulenteId);
    
    return {
      'sessionCount': sessionCount,
      'lastSession': lastSession,
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Hoje';
    } else if (difference == 1) {
      return 'Ontem';
    } else if (difference < 7) {
      return 'Há $difference dias';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteDialog(Consulente consulente, ConsulentesController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Consulente'),
        content: Text('Tem a certeza que deseja eliminar ${consulente.name}?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await controller.deleteConsulente(consulente.id!);
              if (success) {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  const SnackBar(
                    content: Text('Consulente eliminado com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(Get.context!).showSnackBar(
                  SnackBar(
                    content: Text(controller.errorMessage.value),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ConsulentesController controller = Get.find<ConsulentesController>();

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Gestão de Consulentes',
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: () => controller.refreshData(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Erro: ${controller.errorMessage.value}',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadConsulentes(),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildSearchBar(controller),
            _buildStatistics(controller),
            Expanded(
              child: _buildConsulentesList(controller),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const ConsulenteFormScreen()),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar(ConsulentesController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => controller.updateSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Pesquisar por nome, telefone ou email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () => controller.clearSearch(),
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildStatistics(ConsulentesController controller) {
    return FutureBuilder<Map<String, int>>(
      future: controller.getStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        final stats = snapshot.data ?? {
          'total': 0,
          'withSessions': 0,
          'recentSessions': 0,
        };
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', stats['total']!, Colors.blue, Icons.people),
              _buildStatItem('Com Sessões', stats['withSessions']!, Colors.green, Icons.event),
              _buildStatItem('Sessões Recentes', stats['recentSessions']!, Colors.orange, Icons.trending_up),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildConsulentesList(ConsulentesController controller) {
    final filteredConsulentes = controller.filteredConsulentes;

    if (filteredConsulentes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              controller.searchQuery.isNotEmpty
                  ? 'Nenhum consulente encontrado'
                  : 'Nenhum consulente registado',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (controller.searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Toque no botão + para adicionar o primeiro consulente',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredConsulentes.length,
      itemBuilder: (context, index) {
        final consulente = filteredConsulentes[index];
        return _buildConsulenteCard(consulente, controller);
      },
    );
  }

  Widget _buildConsulenteCard(Consulente consulente, ConsulentesController controller) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getConsulenteData(consulente.id!, controller),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const ListTile(
              leading: CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
              title: Text('Carregando...'),
              subtitle: Text('A obter dados da sessão'),
            ),
          );
        }
        
        final sessionCount = snapshot.data?['sessionCount'] ?? 0;
        final lastSession = snapshot.data?['lastSession'] as ConsulenteSession?;

        return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: Text(
            consulente.name.isNotEmpty ? consulente.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          consulente.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: sessionCount > 0
            ? Row(
                children: [
                  Icon(Icons.event, size: 14, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$sessionCount ${sessionCount == 1 ? 'sessão' : 'sessões'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (lastSession != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Última: ${_formatDate(lastSession.sessionDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              )
            : Text(
                'Sem sessões marcadas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view':
                Get.to(() => ConsulenteDetailScreen(consulente: consulente));
                break;
              case 'edit':
                Get.to(() => ConsulenteFormScreen(consulente: consulente));
                break;
              case 'delete':
                _showDeleteDialog(consulente, controller);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('Ver Detalhes'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: Icon(
            Icons.more_vert,
            color: Colors.grey[600],
          ),
        ),
        onTap: () => Get.to(() => ConsulenteDetailScreen(consulente: consulente)),
      ),
    );
      },
    );
  }
}
