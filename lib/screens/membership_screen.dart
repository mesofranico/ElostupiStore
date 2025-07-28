import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/member_controller.dart';
import '../controllers/payment_controller.dart';
import '../models/member.dart';
import '../models/payment.dart';
import '../core/currency_formatter.dart';
import '../core/membership_calculator.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MemberController memberController = Get.put(MemberController());
    final PaymentController paymentController = Get.put(PaymentController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestão de Mensalidades'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Membros'),
              Tab(icon: Icon(Icons.payment), text: 'Pagamentos'),
              Tab(icon: Icon(Icons.analytics), text: 'Relatórios'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddMemberDialog(context, memberController),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildMembersTab(memberController),
            _buildPaymentsTab(paymentController),
            _buildReportsTab(memberController, paymentController),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab(MemberController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Carregar membros ativos por padrão se a lista estiver vazia
      if (controller.members.isEmpty) {
        controller.loadActiveMembers();
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
                onPressed: () => controller.loadMembers(),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        );
      }

      final stats = controller.getStatistics();
      
      return Column(
        children: [
          // Estatísticas
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total', stats['total'].toString(), Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Ativos', stats['active'].toString(), Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Em Atraso', stats['overdue'].toString(), Colors.red),
                ),
              ],
            ),
          ),
          
          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.loadMembers(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Todos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.loadOverdueMembers(),
                    icon: const Icon(Icons.warning),
                    label: const Text('Em Atraso'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.loadActiveMembers(),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Ativos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de membros
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.members.length,
              itemBuilder: (context, index) {
                final member = controller.members[index];
                final isOverdue = controller.isMemberOverdue(member);
                final daysOverdue = controller.getDaysOverdue(member);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  elevation: 1,
                  shadowColor: Colors.grey.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _showMemberDetails(context, member),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          // Avatar e informações principais
                          CircleAvatar(
                            backgroundColor: !member.isActive ? Colors.grey : (isOverdue ? Colors.red : Colors.green),
                            child: Text(
                              member.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          
                          // Informações centrais
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nome e badge INATIVO
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      member.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: !member.isActive ? Colors.grey[600] : null,
                                      ),
                                    ),
                                    if (!member.isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'INATIVO',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                
                                const SizedBox(height: 3),
                                
                                // Valor e próxima data
                                Row(
                                  children: [
                                    Text(
                                      CurrencyFormatter.formatEuro(member.monthlyFee),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    if (member.nextPaymentDate != null)
                                      Row(
                                        children: [
                                          Icon(
                                            isOverdue ? Icons.warning : Icons.calendar_today,
                                            color: isOverdue ? Colors.red : Colors.green,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(member.nextPaymentDate!),
                                            style: TextStyle(
                                              color: isOverdue ? Colors.red : Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                
                                // Informações de atraso (se houver)
                                if (isOverdue) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule, color: Colors.red, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$daysOverdue dias',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (member.overdueMonths != null && member.overdueMonths! > 0) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${member.overdueMonths} mens.',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      if (member.totalOverdue != null && member.totalOverdue! > 0) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${CurrencyFormatter.formatEuro(member.totalOverdue!)}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Botões de ação
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botão Editar
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  onPressed: () => _showEditMemberDialog(context, member, controller),
                                  icon: const Icon(Icons.edit, size: 16),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                    foregroundColor: Colors.blue,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Botão Pagamento
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  onPressed: member.isActive ? () => _showPaymentDialog(context, member) : null,
                                  icon: Icon(
                                    Icons.payment, 
                                    size: 16,
                                    color: member.isActive ? Colors.green : Colors.grey[400],
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: member.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                    foregroundColor: member.isActive ? Colors.green : Colors.grey[400],
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Botão Excluir
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  onPressed: () => _showDeleteConfirmation(context, member, controller),
                                  icon: const Icon(Icons.delete, size: 16),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                                    foregroundColor: Colors.red,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPaymentsTab(PaymentController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final stats = controller.getPaymentStatistics();
      
      return Column(
        children: [
          // Estatísticas de pagamentos
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total', stats['total'].toString(), Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Concluídos', stats['completed'].toString(), Colors.green),
                ),

              ],
            ),
          ),
          
          // Filtros de pagamentos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.loadPayments(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Todos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              ],
            ),
          ),
          
          const SizedBox(height: 16),
          

          
          // Lista de pagamentos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.payments.length,
              itemBuilder: (context, index) {
                final payment = controller.payments[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  elevation: 1,
                  shadowColor: Colors.grey.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () => _showPaymentDetails(context, payment),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          // Linha principal
                          Row(
                            children: [
                              // Status (ícone)
                              SizedBox(
                                width: 40,
                                child: Icon(
                                  _getPaymentStatusIcon(payment.status),
                                  color: _getPaymentStatusColor(payment.status),
                                  size: 20,
                                ),
                              ),
                              
                              // Membro
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Membro',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      payment.memberName ?? 'Membro não encontrado',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Valor
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    Text(
                                      'Valor',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatEuro(payment.amount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Data
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    Text(
                                      'Data',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(payment.paymentDate),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Status (texto)
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    Text(
                                      'Status',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getPaymentStatusColor(payment.status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getPaymentStatusText(payment.status),
                                        style: TextStyle(
                                          color: _getPaymentStatusColor(payment.status),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              

                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildReportsTab(MemberController memberController, PaymentController paymentController) {
    return Builder(
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Relatórios de Mensalidades',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Relatório de membros
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo de Membros',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final stats = memberController.getStatistics();
                      return Column(
                        children: [
                          _buildReportRow('Total de Membros', stats['total'].toString()),
                          _buildReportRow('Membros Ativos', stats['active'].toString()),
                          _buildReportRow('Em Atraso', stats['overdue'].toString()),
                          _buildReportRow('Pagamentos em Dia', stats['paid'].toString()),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Relatório de pagamentos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo de Pagamentos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final stats = paymentController.getPaymentStatistics();
                      return Column(
                        children: [
                          _buildReportRow('Total de Pagamentos', stats['total'].toString()),
                          _buildReportRow('Valor Total', CurrencyFormatter.formatEuro(stats['totalAmount'])),
                          _buildReportRow('Concluídos', stats['completed'].toString()),
                          _buildReportRow('Pendentes', stats['pending'].toString()),
                          _buildReportRow('Falhados', stats['failed'].toString()),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _generateReport(context, memberController, paymentController),
                    icon: const Icon(Icons.download),
                    label: const Text('Gerar Relatório'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDateRangeDialog(context, paymentController),
                    icon: const Icon(Icons.date_range),
                    label: const Text('Período'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return CurrencyFormatter.formatDate(date);
  }

  // Capitalizar primeira letra
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Função para obter opções de mensalidades baseadas no tipo
  List<Map<String, dynamic>> _getAdvanceOptions(String membershipType) {
    switch (membershipType.toLowerCase()) {
      case 'mensal':
        return [
          {'months': 1, 'label': '1 Mês'},
          {'months': 2, 'label': '2 Meses'},
          {'months': 3, 'label': '3 Meses'},
        ];
      case 'trimestral':
        return [
          {'months': 1, 'label': '1 Trimestre'},
          {'months': 2, 'label': '2 Trimestres'},
          {'months': 3, 'label': '3 Trimestres'},
        ];
      case 'semestral':
        return [
          {'months': 1, 'label': '1 Semestre'},
          {'months': 2, 'label': '2 Semestres'},
        ];
      case 'anual':
        return [
          {'months': 1, 'label': '1 Ano'},
          {'months': 2, 'label': '2 Anos'},
        ];
      default:
        return [
          {'months': 1, 'label': '1 Período'},
          {'months': 2, 'label': '2 Períodos'},
          {'months': 3, 'label': '3 Períodos'},
        ];
    }
  }

  // Função para calcular valor total baseado no tipo de mensalidade
  double _calculateTotalAmount(String membershipType, double monthlyFee, int numberOfPeriods) {
    switch (membershipType.toLowerCase()) {
      case 'mensal':
        // Para mensal, multiplicar pelo número de meses
        return monthlyFee * numberOfPeriods;
      case 'trimestral':
        // Para trimestral, o monthlyFee já é o valor do trimestre
        return monthlyFee * numberOfPeriods;
      case 'semestral':
        // Para semestral, o monthlyFee já é o valor do semestre
        return monthlyFee * numberOfPeriods;
      case 'anual':
        // Para anual, o monthlyFee já é o valor do ano
        return monthlyFee * numberOfPeriods;
      default:
        return monthlyFee * numberOfPeriods;
    }
  }



  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Concluído';
      case 'pending':
        return 'Pendente';
      case 'failed':
        return 'Falhado';
      default:
        return 'Desconhecido';
    }
  }

  void _showAddMemberDialog(BuildContext context, MemberController controller) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final feeController = TextEditingController();
    String selectedMembershipType = 'Mensal';
    bool isActive = true;
    
    Get.dialog(
      AlertDialog(
        title: const Text('Novo Membro'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  border: OutlineInputBorder(),
                  hintText: '(351) 999999999',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMembershipType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Mensalidade *',
                  border: OutlineInputBorder(),
                ),
                items: ['Mensal', 'Trimestral', 'Semestral', 'Anual']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedMembershipType = value!;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feeController,
                decoration: const InputDecoration(
                  labelText: 'Valor da Mensalidade (€) *',
                  border: OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: isActive,
                    onChanged: (value) {
                      isActive = value!;
                    },
                  ),
                  const Text('Membro Ativo'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validação
              if (nameController.text.trim().isEmpty) {
                Get.snackbar(
                  'Erro',
                  'Nome é obrigatório',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              
              if (feeController.text.trim().isEmpty) {
                Get.snackbar(
                  'Erro',
                  'Valor da mensalidade é obrigatório',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              
              final fee = double.tryParse(feeController.text.replaceAll(',', '.'));
              if (fee == null || fee <= 0) {
                Get.snackbar(
                  'Erro',
                  'Valor da mensalidade deve ser um número válido',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              
              try {
                // Criar novo membro
                final newMember = Member(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  membershipType: selectedMembershipType,
                  monthlyFee: fee,
                  joinDate: DateTime.now(),
                  isActive: isActive,
                  paymentStatus: 'pending',
                  nextPaymentDate: MembershipCalculator.calculateFirstPaymentDate(DateTime.now()),
                );
                
                // Salvar membro
                final success = await controller.createMember(newMember);
                
                if (success) {
                  Get.back(); // Fechar diálogo
                  
                  Get.snackbar(
                    'Membro Adicionado',
                    'Membro ${newMember.name} adicionado com sucesso!',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 3),
                  );
                } else {
                  Get.snackbar(
                    'Erro',
                    'Erro ao adicionar membro. Tente novamente.',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 3),
                  );
                }
              } catch (e) {
                Get.snackbar(
                  'Erro',
                  'Erro ao adicionar membro: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showEditMemberDialog(BuildContext context, Member member, MemberController controller) {
    final nameController = TextEditingController(text: member.name);
    final emailController = TextEditingController(text: member.email);
    final phoneController = TextEditingController(text: member.phone);
    final feeController = TextEditingController(text: member.monthlyFee.toString());
    String selectedMembershipType = member.membershipType;
    bool isActive = member.isActive;
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabeçalho
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue,
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editar Membro',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Conteúdo
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Informações pessoais
                          _buildEditSection(
                            'Informações Pessoais',
                            [
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nome Completo *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Telefone',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                  hintText: '(351) 999999999',
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Informações financeiras
                          _buildEditSection(
                            'Informações Financeiras',
                            [
                              // Verificar se há pagamentos em atraso
                              Builder(
                                builder: (context) {
                                  final isOverdue = member.overdueMonths != null && member.overdueMonths! > 0;
                                  
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: selectedMembershipType,
                                        decoration: InputDecoration(
                                          labelText: 'Tipo de Mensalidade *',
                                          border: const OutlineInputBorder(),
                                          prefixIcon: const Icon(Icons.category),
                                          suffixIcon: isOverdue 
                                              ? Tooltip(
                                                  message: 'Não é possível alterar o tipo de mensalidade quando há pagamentos em atraso',
                                                  child: Icon(
                                                    Icons.warning,
                                                    color: Colors.orange,
                                                    size: 20,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        items: ['Mensal', 'Trimestral', 'Semestral', 'Anual']
                                            .map((type) => DropdownMenuItem(
                                                  value: type,
                                                  child: Text(type),
                                                ))
                                            .toList(),
                                        onChanged: isOverdue ? null : (value) {
                                          setState(() {
                                            selectedMembershipType = value!;
                                          });
                                        },
                                      ),
                                      if (isOverdue) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.orange[200]!),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.warning,
                                                color: Colors.orange[700],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Não é possível alterar o tipo de mensalidade enquanto houver pagamentos em atraso (${member.overdueMonths} mensalidade${member.overdueMonths! > 1 ? 's' : ''})',
                                                  style: TextStyle(
                                                    color: Colors.orange[700],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: feeController,
                                decoration: const InputDecoration(
                                  labelText: 'Valor da Mensalidade (€) *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.euro),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Status do membro
                          _buildEditSection(
                            'Status do Membro',
                            [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isActive,
                                      onChanged: (value) {
                                        setState(() {
                                          isActive = value!;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Membro Ativo',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            isActive 
                                                ? 'Membro pode realizar pagamentos'
                                                : 'Membro suspenso de pagamentos',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.green[100] : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isActive ? 'ATIVO' : 'INATIVO',
                                        style: TextStyle(
                                          color: isActive ? Colors.green[700] : Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Botões de ação
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            // Validação
                            if (nameController.text.trim().isEmpty) {
                              Get.snackbar(
                                'Erro',
                                'Nome é obrigatório',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }
                            
                            if (feeController.text.trim().isEmpty) {
                              Get.snackbar(
                                'Erro',
                                'Valor da mensalidade é obrigatório',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }
                            
                            final fee = double.tryParse(feeController.text.replaceAll(',', '.'));
                            if (fee == null || fee <= 0) {
                              Get.snackbar(
                                'Erro',
                                'Valor da mensalidade deve ser um número válido',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }
                            
                            // Verificar se está tentando alterar o tipo de mensalidade com pagamentos em atraso
                            final isOverdue = member.overdueMonths != null && member.overdueMonths! > 0;
                            final isChangingMembershipType = selectedMembershipType != member.membershipType;
                            
                            if (isOverdue && isChangingMembershipType) {
                              Get.snackbar(
                                'Erro',
                                'Não é possível alterar o tipo de mensalidade enquanto houver pagamentos em atraso. Regularize os pagamentos primeiro.',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                                duration: const Duration(seconds: 4),
                              );
                              return;
                            }
                            
                            try {
                              // Atualizar membro
                              final updatedMember = member.copyWith(
                                name: nameController.text.trim(),
                                email: emailController.text.trim(),
                                phone: phoneController.text.trim(),
                                membershipType: selectedMembershipType,
                                monthlyFee: fee,
                                isActive: isActive,
                              );
                              
                              // Salvar alterações
                              final success = await controller.updateMember(updatedMember);
                              
                              if (success) {
                                Get.back(); // Fechar diálogo
                                
                                Get.snackbar(
                                  'Membro Atualizado',
                                  'Membro ${updatedMember.name} atualizado com sucesso!',
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 3),
                                );
                              } else {
                                Get.snackbar(
                                  'Erro',
                                  'Erro ao atualizar membro. Tente novamente.',
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 3),
                                );
                              }
                            } catch (e) {
                              Get.snackbar(
                                'Erro',
                                'Erro ao atualizar membro: $e',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                                duration: const Duration(seconds: 3),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Atualizar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Member member) {
    final PaymentController paymentController = Get.find<PaymentController>();
    final MemberController memberController = Get.find<MemberController>();
    
    // Verificar se membro está ativo
    if (!member.isActive) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.person_off,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Membro Inativo',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              member.name,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Conteúdo
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'O membro ${member.name} está inativo.',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Membros inativos não podem realizar pagamentos de mensalidades.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Botão de fechar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Fechar'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    
    // Estado do diálogo
    final overdueMonths = member.overdueMonths ?? 0;
    final overdueAmount = member.totalOverdue ?? 0;
    
    // Definir tipo de pagamento padrão
    String paymentType = overdueMonths > 0 ? 'overdue' : 'advance';
    int numberOfMonths = 1;
    double totalAmount = overdueMonths > 0 ? overdueAmount : _calculateTotalAmount(member.membershipType, member.monthlyFee, numberOfMonths);
    
    // Se há atrasos, forçar tipo de pagamento para 'overdue'
    if (overdueMonths > 0) {
      paymentType = 'overdue';
      totalAmount = overdueAmount;
    }
    
    void updateTotalAmount() {
      switch (paymentType) {
        case 'overdue':
          totalAmount = overdueAmount;
          break;
        case 'advance':
          // Só permitir pagamentos antecipados se não há atrasos
          if (overdueMonths == 0) {
            totalAmount = _calculateTotalAmount(member.membershipType, member.monthlyFee, numberOfMonths);
          } else {
            totalAmount = overdueAmount;
          }
          break;
        default:
          totalAmount = overdueMonths > 0 ? overdueAmount : _calculateTotalAmount(member.membershipType, member.monthlyFee, numberOfMonths);
      }
    }
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          updateTotalAmount();
          
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabeçalho
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green,
                          child: Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registar Pagamento',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Conteúdo
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Informações do membro
                          _buildEditSection(
                            'Informações do Membro',
                            [
                              _buildInfoRow(Icons.person, 'Nome', member.name),
                              _buildInfoRow(Icons.category, 'Tipo', _capitalizeFirstLetter(member.membershipType)),
                              _buildInfoRow(Icons.euro, 'Mensalidade', CurrencyFormatter.formatEuro(member.monthlyFee)),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Opções de pagamento
                          _buildEditSection(
                            'Tipo de Pagamento',
                            [
                              // Pagamento em atraso (se houver)
                              if (overdueMonths > 0)
                                RadioListTile<String>(
                                  title: const Text('Mensalidades em Atraso'),
                                  subtitle: Text('$overdueMonths mensalidade${overdueMonths > 1 ? 's' : ''} - ${CurrencyFormatter.formatEuro(overdueAmount)}'),
                                  value: 'overdue',
                                  groupValue: paymentType,
                                  onChanged: (value) {
                                    setState(() {
                                      paymentType = value!;
                                    });
                                  },
                                ),
                              
                              // Pagamento antecipado (apenas se não há atrasos)
                              if (overdueMonths == 0)
                                RadioListTile<String>(
                                  title: const Text('Mensalidades Antecipadas'),
                                  subtitle: Text('${_getAdvanceOptions(member.membershipType).firstWhere((opt) => opt['months'] == numberOfMonths)['label'].toLowerCase()} - ${CurrencyFormatter.formatEuro(_calculateTotalAmount(member.membershipType, member.monthlyFee, numberOfMonths))}'),
                                  value: 'advance',
                                  groupValue: paymentType,
                                  onChanged: (value) {
                                    setState(() {
                                      paymentType = value!;
                                    });
                                  },
                                ),
                            ],
                          ),
                          
                          // Seletor de número de mensalidades antecipadas (apenas se não há atrasos)
                          if (paymentType == 'advance' && overdueMonths == 0) ...[
                            const SizedBox(height: 20),
                            _buildEditSection(
                              'Número de Mensalidades',
                              [
                                Row(
                                  children: _getAdvanceOptions(member.membershipType).map((option) {
                                    final months = option['months'] as int;
                                    final label = option['label'] as String;
                                    
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            numberOfMonths = months;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: numberOfMonths == months ? Colors.green : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: numberOfMonths == months ? Colors.green : Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Text(
                                            label,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: numberOfMonths == months ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 20),
                          
                          // Valor total
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Valor Total:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatEuro(totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Botões de ação
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              int monthsToAdvance;
                              
                              // Determinar meses baseado no tipo de pagamento
                              switch (paymentType) {
                                case 'overdue':
                                  monthsToAdvance = overdueMonths;
                                  break;
                                case 'advance':
                                  monthsToAdvance = numberOfMonths;
                                  break;
                                default:
                                  monthsToAdvance = numberOfMonths;
                              }
                              
                              // Criar o pagamento
                              final payment = Payment(
                                memberId: member.id!,
                                amount: totalAmount,
                                paymentDate: DateTime.now(),
                                status: 'completed',
                                createdAt: DateTime.now(),
                              );
                              
                              // Salvar o pagamento
                              final success = await paymentController.createPayment(payment);
                              
                              if (success) {
                                // Calcular próxima data de pagamento
                                DateTime nextPaymentDate;
                                final currentPaymentDate = DateTime.now();
                                
                                if (paymentType == 'overdue') {
                                  // Para pagamentos em atraso, calcular baseado na última data de pagamento
                                  // Se não há último pagamento, usar o primeiro dia do mês seguinte ao ingresso
                                  final baseDate = member.lastPaymentDate ?? 
                                      MembershipCalculator.calculateFirstPaymentDate(member.joinDate);
                                  nextPaymentDate = MembershipCalculator.calculateNextPaymentAfterOverdue(
                                    baseDate,
                                    member.membershipType,
                                    monthsToAdvance
                                  );
                                } else {
                                  // Para pagamentos antecipados, calcular baseado na próxima data atual + meses adiantados
                                  final baseDate = member.nextPaymentDate ?? currentPaymentDate;
                                  nextPaymentDate = MembershipCalculator.calculateNextPaymentByType(
                                    member.membershipType,
                                    fromDate: baseDate
                                  );
                                  
                                  // Adicionar os meses adiantados restantes
                                  for (int i = 1; i < monthsToAdvance; i++) {
                                    nextPaymentDate = MembershipCalculator.calculateNextPaymentByType(
                                      member.membershipType,
                                      fromDate: nextPaymentDate
                                    );
                                  }
                                }
                                
                                // Determinar o status do pagamento baseado se há atrasos
                                String paymentStatus = 'paid';
                                if (member.overdueMonths != null && member.overdueMonths! > 0) {
                                  // Se havia atrasos e foram pagos, verificar se ainda há atrasos
                                  final remainingOverdue = MembershipCalculator.calculateOverdueMonths(
                                    member.joinDate, 
                                    currentPaymentDate, 
                                    member.membershipType
                                  );
                                  if (remainingOverdue > 0) {
                                    paymentStatus = 'overdue';
                                  }
                                }
                                
                                final updatedMember = member.copyWith(
                                  lastPaymentDate: currentPaymentDate,
                                  nextPaymentDate: nextPaymentDate,
                                  paymentStatus: paymentStatus,
                                );
                                
                                await memberController.updateMember(updatedMember);
                                
                                // Recarregar dados
                                await memberController.loadMembers();
                                await paymentController.loadPayments();
                                
                                Get.back(); // Fechar diálogo
                                
                                Get.snackbar(
                                  'Pagamento Registado',
                                  'Pagamento de ${CurrencyFormatter.formatEuro(totalAmount)} registado com sucesso!',
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 3),
                                );
                              } else {
                                Get.back(); // Fechar diálogo
                                Get.snackbar(
                                  'Erro',
                                  'Erro ao registar pagamento. Tente novamente.',
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 3),
                                );
                              }
                            } catch (e) {
                              Get.back(); // Fechar diálogo
                              Get.snackbar(
                                'Erro',
                                'Erro ao registar pagamento: $e',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                                duration: const Duration(seconds: 3),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Confirmar Pagamento'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Member member, MemberController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o membro ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              controller.deleteMember(member.id!);
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showMemberDetails(BuildContext context, Member member) {
    final isOverdue = member.overdueMonths != null && member.overdueMonths! > 0;
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isOverdue ? Colors.red[50] : Colors.green[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isOverdue ? Colors.red : Colors.green,
                      child: Text(
                        member.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isOverdue ? Colors.red[100] : Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _capitalizeFirstLetter(member.membershipType),
                              style: TextStyle(
                                color: isOverdue ? Colors.red[700] : Colors.green[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Conteúdo
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Informações de contato
                    _buildInfoSection(
                      'Informações de Contato',
                      [
                        _buildInfoRow(Icons.email, 'Email', member.email?.isNotEmpty == true ? member.email! : 'Não informado'),
                        _buildInfoRow(Icons.phone, 'Telefone', member.phone.isNotEmpty ? member.phone : 'Não informado'),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Informações financeiras
                    _buildInfoSection(
                      'Informações Financeiras',
                      [
                        _buildInfoRow(Icons.euro, 'Mensalidade', CurrencyFormatter.formatEuro(member.monthlyFee)),
                        _buildInfoRow(Icons.calendar_today, 'Data de Ingresso', _formatDate(member.joinDate)),
                        if (member.lastPaymentDate != null)
                          _buildInfoRow(Icons.payment, 'Último Pagamento', _formatDate(member.lastPaymentDate!)),
                        if (member.nextPaymentDate != null)
                          _buildInfoRow(
                            isOverdue ? Icons.warning : Icons.schedule,
                            'Próximo Pagamento',
                            _formatDate(member.nextPaymentDate!),
                            isOverdue ? Colors.red : null,
                          ),
                      ],
                    ),
                    
                    // Informações de atraso (se houver)
                    if (isOverdue) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Pagamentos em Atraso',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.schedule, 'Dias em atraso', '${member.overdueMonths! * 30} dias', Colors.red),
                            _buildInfoRow(Icons.payment, 'Mensalidades em atraso', '${member.overdueMonths} mensalidade${member.overdueMonths! > 1 ? 's' : ''}', Colors.red),
                            _buildInfoRow(Icons.euro, 'Total em atraso', CurrencyFormatter.formatEuro(member.totalOverdue ?? 0), Colors.red),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: member.isActive ? Colors.green[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: member.isActive ? Colors.green[200]! : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            member.isActive ? Icons.check_circle : Icons.cancel,
                            color: member.isActive ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Status: ${member.isActive ? 'Ativo' : 'Inativo'}',
                            style: TextStyle(
                              color: member.isActive ? Colors.green[700] : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Botão de fechar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Fechar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildEditSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(BuildContext context, Payment payment) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getPaymentStatusColor(payment.status).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _getPaymentStatusColor(payment.status),
                      child: Icon(
                        _getPaymentStatusIcon(payment.status),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pagamento',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getPaymentStatusColor(payment.status).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getPaymentStatusText(payment.status),
                              style: TextStyle(
                                color: _getPaymentStatusColor(payment.status),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Conteúdo
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Informações do pagamento
                    _buildInfoSection(
                      'Informações do Pagamento',
                      [
                        _buildInfoRow(Icons.person, 'Membro', payment.memberName ?? 'Não informado'),
                        _buildInfoRow(Icons.euro, 'Valor', CurrencyFormatter.formatEuro(payment.amount)),
                        _buildInfoRow(Icons.calendar_today, 'Data', _formatDate(payment.paymentDate)),
                        _buildInfoRow(Icons.access_time, 'Criado em', _formatDate(payment.createdAt)),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Botão de fechar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Fechar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _generateReport(BuildContext context, MemberController memberController, PaymentController paymentController) {
    // Implementar geração de relatório
    Get.snackbar(
      'Relatório',
      'Relatório gerado com sucesso!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _showDateRangeDialog(BuildContext context, PaymentController controller) {
    // Implementar seleção de período
    Get.dialog(
      AlertDialog(
        title: const Text('Selecionar Período'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
} 