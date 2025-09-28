import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/member_controller.dart';
import '../controllers/payment_controller.dart';
import '../models/member.dart';
import '../models/payment.dart';
import '../core/currency_formatter.dart';
import '../core/membership_calculator.dart';
import '../core/snackbar_helper.dart';

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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => _showAddMemberDialog(context, memberController),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Novo Membro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
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
                    onPressed: () => controller.refreshData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar'),
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
                              // Botão Pagamento (primeiro e maior)
                              ElevatedButton.icon(
                                onPressed: member.isActive ? () => _showPaymentDialog(context, member) : null,
                                icon: Icon(
                                  Icons.payment, 
                                  size: 16,
                                  color: member.isActive ? Colors.white : Colors.grey[400],
                                ),
                                label: Text(
                                  'Pagamento',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: member.isActive ? Colors.white : Colors.grey[400],
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: member.isActive ? Colors.green : Colors.grey[300],
                                  foregroundColor: member.isActive ? Colors.white : Colors.grey[400],
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: const Size(0, 28),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Botão Editar
                              ElevatedButton.icon(
                                onPressed: () => _showEditMemberDialog(context, member, controller),
                                icon: const Icon(Icons.edit, size: 14),
                                label: const Text(
                                  'Editar',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: const Size(0, 28),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Botão Excluir
                              ElevatedButton.icon(
                                onPressed: () => _showDeleteConfirmation(context, member, controller),
                                icon: const Icon(Icons.delete, size: 14),
                                label: const Text(
                                  'Excluir',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: const Size(0, 28),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
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
                              
                              // Tipo de Pagamento
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    Text(
                                      'Tipo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getPaymentTypeColor(payment.paymentType).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getPaymentTypeText(payment.paymentType),
                                        style: TextStyle(
                                          color: _getPaymentTypeColor(payment.paymentType),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
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
            // Cabeçalho
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue[700], size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
              'Relatórios de Mensalidades',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        Text(
                          'Análise completa do sistema de mensalidades',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Indicador de filtro ativo
            Obx(() {
              if (memberController.filterStartDate.value != null && memberController.filterEndDate.value != null) {
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Filtro ativo: ${_formatDate(memberController.filterStartDate.value!)} a ${_formatDate(memberController.filterEndDate.value!)}',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _clearDateFilter(memberController),
                        child: Text(
                          'Limpar',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            
            const SizedBox(height: 20),
            
            // Estatísticas em Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatisticCard(
                    'Total de Membros',
                    Obx(() => Text(
                      memberController.getFilteredMembers().length.toString(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                    )),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatisticCard(
                    'Membros Ativos',
                    Obx(() => Text(
                      memberController.getFilteredMembers().where((m) => m.isActive).length.toString(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                    )),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatisticCard(
                    'Em Atraso',
                    Obx(() => Text(
                      memberController.getFilteredMembers().where((m) => 
                        m.paymentStatus == 'overdue' || 
                        (m.nextPaymentDate != null && m.nextPaymentDate!.isBefore(DateTime.now()))
                      ).length.toString(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
                    )),
                    Icons.warning,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatisticCard(
                    'Valor Total',
                    Obx(() => Text(
                      CurrencyFormatter.formatEuro(
                        paymentController.getFilteredPayments().fold<double>(0, (sum, p) => sum + p.amount)
                      ),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                    )),
                    Icons.euro,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Relatório Detalhado de Membros
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.blue[700], size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Análise de Membros',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      final filteredMembers = memberController.getFilteredMembers();
                      final total = filteredMembers.length;
                      final active = filteredMembers.where((m) => m.isActive).length;
                      final overdue = filteredMembers.where((m) => 
                        m.paymentStatus == 'overdue' || 
                        (m.nextPaymentDate != null && m.nextPaymentDate!.isBefore(DateTime.now()))
                      ).length;
                      final paid = filteredMembers.where((m) => m.paymentStatus == 'paid').length;
                      
                      return Column(
                        children: [
                          _buildDetailedReportRow('Total de Membros', total.toString(), Icons.people, Colors.blue),
                          _buildDetailedReportRow('Membros Ativos', active.toString(), Icons.check_circle, Colors.green),
                          _buildDetailedReportRow('Em Atraso', overdue.toString(), Icons.warning, Colors.red),
                          _buildDetailedReportRow('Pagamentos em Dia', paid.toString(), Icons.payment, Colors.green),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Relatório Detalhado de Pagamentos
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: Colors.green[700], size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Análise de Pagamentos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      final filteredPayments = paymentController.getFilteredPayments();
                      final total = filteredPayments.length;
                      final totalAmount = filteredPayments.fold<double>(0, (sum, p) => sum + p.amount);
                      final completed = filteredPayments.where((p) => p.status == 'completed').length;
                      
                      // Calcular estatísticas por tipo
                      final regularPayments = filteredPayments.where((p) => p.paymentType == 'regular').length;
                      final overduePayments = filteredPayments.where((p) => p.paymentType == 'overdue').length;
                      final advancePayments = filteredPayments.where((p) => p.paymentType == 'advance').length;
                      
                      return Column(
                        children: [
                          _buildDetailedReportRow('Total de Pagamentos', total.toString(), Icons.payment, Colors.blue),
                          _buildDetailedReportRow('Valor Total', CurrencyFormatter.formatEuro(totalAmount), Icons.euro, Colors.orange),
                          _buildDetailedReportRow('Concluídos', completed.toString(), Icons.check_circle, Colors.green),
                          const Divider(height: 24),
                          _buildDetailedReportRow('Pagamentos Regulares', regularPayments.toString(), Icons.schedule, Colors.blue),
                          _buildDetailedReportRow('Pagamentos em Atraso', overduePayments.toString(), Icons.warning, Colors.red),
                          _buildDetailedReportRow('Pagamentos Antecipados', advancePayments.toString(), Icons.trending_up, Colors.green),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Botões de Ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _generateReport(context, memberController, paymentController),
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar Relatório'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDateRangeDialog(context, paymentController),
                    icon: const Icon(Icons.date_range),
                    label: const Text('Filtrar Período'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
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


  Widget _buildStatisticCard(String title, Widget value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            value,
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedReportRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
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

  Color _getPaymentTypeColor(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'regular':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      case 'advance':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentTypeText(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'regular':
        return 'Mensal';
      case 'overdue':
        return 'Atraso';
      case 'advance':
        return 'Adiantado';
      default:
        return 'Regular';
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
                            Icons.person_add,
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
                                'Novo Membro',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Adicionar novo membro à corrente',
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
                  labelText: 'Telefone *',
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
              DropdownButtonFormField<String>(
                initialValue: selectedMembershipType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Mensalidade *',
                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category),
                ),
                items: ['Mensal', 'Trimestral', 'Semestral', 'Anual']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                                  setState(() {
                  selectedMembershipType = value!;
                                  });
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
                SnackBarHelper.showWarning(context, 'O nome é obrigatório');
                return;
              }
              
              if (phoneController.text.trim().isEmpty) {
                SnackBarHelper.showWarning(context, 'O telefone é obrigatório');
                return;
              }
              
              if (feeController.text.trim().isEmpty) {
                SnackBarHelper.showWarning(context, 'O valor da mensalidade é obrigatório');
                return;
              }
              
              final fee = double.tryParse(feeController.text.replaceAll(',', '.'));
              if (fee == null || fee <= 0) {
                SnackBarHelper.showWarning(context, 'O valor da mensalidade deve ser um número positivo');
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
                  // Recarregar dados
                  await controller.loadMembers();
                  
                  // Mostrar mensagem de sucesso
                  if (context.mounted) {
                    SnackBarHelper.showSuccess(context, 'Membro criado com sucesso!');
                  }
                } else {
                  // Mostrar erro
                  final errorMsg = controller.errorMessage.value.isNotEmpty 
                      ? controller.errorMessage.value 
                      : 'Erro desconhecido ao criar membro';
                  if (context.mounted) {
                    SnackBarHelper.showError(context, errorMsg);
                  }
                }
              } catch (e) {
                // Mostrar erro detalhado
                if (context.mounted) {
                  SnackBarHelper.showError(context, 'Erro inesperado: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
                          child: const Text('Adicionar Membro'),
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
                                        initialValue: selectedMembershipType,
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
                              return;
                            }
                            
                            if (feeController.text.trim().isEmpty) {
                              return;
                            }
                            
                            final fee = double.tryParse(feeController.text.replaceAll(',', '.'));
                            if (fee == null || fee <= 0) {
                              return;
                            }
                            
                            // Verificar se está tentando alterar o tipo de mensalidade com pagamentos em atraso
                            final isOverdue = member.overdueMonths != null && member.overdueMonths! > 0;
                            final isChangingMembershipType = selectedMembershipType != member.membershipType;
                            
                            if (isOverdue && isChangingMembershipType) {
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
                                // Recarregar dados
                                await controller.loadMembers();
                              }
                            } catch (e) {
                              // Erro silencioso - o usuário pode tentar novamente
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
    String paymentType = overdueMonths > 0 ? 'overdue' : 'regular';
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
        case 'regular':
          totalAmount = member.monthlyFee;
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
          totalAmount = overdueMonths > 0 ? overdueAmount : member.monthlyFee;
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
                              RadioGroup<String>(
                                groupValue: paymentType,
                                onChanged: (value) {
                                  setState(() {
                                    paymentType = value!;
                                    if (value == 'regular') {
                                      numberOfMonths = 1;
                                    }
                                  });
                                },
                                child: Column(
                                  children: [
                                    // Pagamento em atraso (se houver)
                                    if (overdueMonths > 0)
                                      RadioListTile<String>(
                                        title: const Text('Mensalidades em Atraso'),
                                        subtitle: Text('$overdueMonths mensalidade${overdueMonths > 1 ? 's' : ''} - ${CurrencyFormatter.formatEuro(overdueAmount)}'),
                                        value: 'overdue',
                                      ),
                                    
                                    // Pagamento mensal regular (apenas se não há atrasos)
                                    if (overdueMonths == 0)
                                      RadioListTile<String>(
                                        title: const Text('Mensalidade Regular'),
                                        subtitle: Text('1 ${_capitalizeFirstLetter(member.membershipType).toLowerCase()} - ${CurrencyFormatter.formatEuro(member.monthlyFee)}'),
                                        value: 'regular',
                                      ),
                                    
                                    // Pagamento antecipado (apenas se não há atrasos)
                                    if (overdueMonths == 0)
                                      RadioListTile<String>(
                                        title: const Text('Mensalidades Antecipadas'),
                                        subtitle: Text('${_getAdvanceOptions(member.membershipType).firstWhere((opt) => opt['months'] == numberOfMonths)['label'].toLowerCase()} - ${CurrencyFormatter.formatEuro(_calculateTotalAmount(member.membershipType, member.monthlyFee, numberOfMonths))}'),
                                        value: 'advance',
                                      ),
                                  ],
                                ),
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
                                case 'regular':
                                  monthsToAdvance = 1;
                                  break;
                                case 'advance':
                                  monthsToAdvance = numberOfMonths;
                                  break;
                                default:
                                  monthsToAdvance = 1;
                              }
                              
                              // Criar o pagamento
                              if (kDebugMode) {
                                print('Criando pagamento com tipo: $paymentType');
                              }
                              final payment = Payment(
                                memberId: member.id!,
                                amount: totalAmount,
                                paymentDate: DateTime.now(),
                                status: 'completed',
                                paymentType: paymentType,
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
                                } else if (paymentType == 'regular') {
                                  // Para pagamentos regulares, calcular próxima data normal
                                  final baseDate = member.nextPaymentDate ?? currentPaymentDate;
                                  nextPaymentDate = MembershipCalculator.calculateNextPaymentByType(
                                    member.membershipType,
                                    fromDate: baseDate
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
                                
                                Get.back(); // Fechar diálogo
                                
                                // Recarregar dados
                                await memberController.loadMembers();
                                await paymentController.loadPayments();
                              } else {
                                Get.back(); // Fechar diálogo
                              }
                            } catch (e) {
                              Get.back(); // Fechar diálogo
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
    // Buscar informações sobre pagamentos do membro
    final PaymentController paymentController = Get.find<PaymentController>();
    final memberPayments = paymentController.payments.where((p) => p.memberId == member.id).toList();
    final totalPayments = memberPayments.length;
    final totalAmount = memberPayments.fold<double>(0, (sum, p) => sum + p.amount);
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.red,
                      child: Icon(
                        Icons.warning,
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
                            'Confirmar Exclusão',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Esta ação não pode ser desfeita',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tem certeza que deseja excluir o membro:',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    
                    // Informações do membro
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  member.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _capitalizeFirstLetter(member.membershipType),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
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
                    
                    const SizedBox(height: 16),
                    
                    // Aviso sobre dados que serão removidos
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
                              Icon(Icons.delete_forever, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Dados que serão removidos:',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.person, 'Perfil do membro', 'Completamente removido', Colors.red),
                          _buildInfoRow(Icons.payment, 'Histórico de pagamentos', '$totalPayments pagamento(s)', Colors.red),
                          _buildInfoRow(Icons.euro, 'Valor total em pagamentos', CurrencyFormatter.formatEuro(totalAmount), Colors.red),
                          _buildInfoRow(Icons.schedule, 'Datas e status', 'Todas as informações temporais', Colors.red),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Aviso final
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange[700], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esta ação é irreversível. Todos os dados relacionados ao membro serão permanentemente removidos da base de dados.',
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
                          final success = await controller.deleteMember(member.id!);
                          Get.back(); // Fechar diálogo
                          
                          if (success) {
                            // Recarregar dados
                            await controller.loadMembers();
                            
                            // Mostrar mensagem de sucesso
                            if (context.mounted) {
                              SnackBarHelper.showSuccess(
                                context, 
                                'Membro "${member.name}" foi excluído com sucesso'
                              );
                            }
                          } else {
                            // Mostrar mensagem de erro
                            if (context.mounted) {
                              SnackBarHelper.showError(
                                context, 
                                controller.errorMessage.value.isNotEmpty 
                                  ? controller.errorMessage.value
                                  : 'Erro ao excluir membro. Tente novamente.'
                              );
                            }
                          }
                        } catch (e) {
                          Get.back(); // Fechar diálogo
                          
                          // Mostrar mensagem de erro
                          if (context.mounted) {
                            SnackBarHelper.showError(
                              context, 
                              'Erro inesperado ao excluir membro: $e'
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirmar Exclusão'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                          Row(
                            children: [
                          Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getPaymentTypeColor(payment.paymentType).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getPaymentTypeText(payment.paymentType),
                                  style: TextStyle(
                                    color: _getPaymentTypeColor(payment.paymentType),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPaymentStatusColor(payment.status).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getPaymentStatusText(payment.status),
                              style: TextStyle(
                                color: _getPaymentStatusColor(payment.status),
                                fontWeight: FontWeight.w600,
                                    fontSize: 12,
                              ),
                            ),
                              ),
                            ],
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
                        _buildInfoRow(Icons.category, 'Tipo', _getPaymentTypeText(payment.paymentType)),
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
    final now = DateTime.now();
    final formattedDate = CurrencyFormatter.formatDate(now);
    
    // Gerar conteúdo do relatório
    final reportContent = _generateReportContent(memberController, paymentController, formattedDate);
    
    // Mostrar diálogo com o relatório
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: Column(
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
                    Icon(Icons.description, color: Colors.green[700], size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Relatório de Mensalidades',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            'Gerado em $formattedDate',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Conteúdo do relatório
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(
                    reportContent,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
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
                      child: const Text('Fechar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _copyReportToClipboard(context, reportContent),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
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
  }

  String _generateReportContent(MemberController memberController, PaymentController paymentController, String date) {
    final members = memberController.getFilteredMembers();
    final payments = paymentController.getFilteredPayments();
    
    // Estatísticas gerais
    final totalMembers = members.length;
    final activeMembers = members.where((m) => m.isActive).length;
    final overdueMembers = members.where((m) => 
      m.paymentStatus == 'overdue' || 
      (m.nextPaymentDate != null && m.nextPaymentDate!.isBefore(DateTime.now()))
    ).length;
    final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amount);
    
    // Estatísticas por tipo de pagamento
    final regularPayments = payments.where((p) => p.paymentType == 'regular').length;
    final overduePayments = payments.where((p) => p.paymentType == 'overdue').length;
    final advancePayments = payments.where((p) => p.paymentType == 'advance').length;
    
    // Membros em atraso detalhados
    final overdueMembersList = members.where((m) => 
      m.paymentStatus == 'overdue' || 
      (m.nextPaymentDate != null && m.nextPaymentDate!.isBefore(DateTime.now()))
    ).toList();
    
    // Últimos pagamentos
    final recentPayments = payments.take(10).toList();
    
    StringBuffer report = StringBuffer();
    
    // Cabeçalho do relatório
    report.writeln('=' * 60);
    report.writeln('RELATÓRIO DE MENSUALIDADES - ELOSTUPI STORE');
    report.writeln('=' * 60);
    report.writeln('Data de geração: $date');
    report.writeln('');
    
    // Resumo executivo
    report.writeln('RESUMO EXECUTIVO');
    report.writeln('-' * 30);
    report.writeln('Total de Membros: $totalMembers');
    report.writeln('Membros Ativos: $activeMembers');
    report.writeln('Membros em Atraso: $overdueMembers');
    report.writeln('Valor Total em Pagamentos: ${CurrencyFormatter.formatEuro(totalAmount)}');
    report.writeln('');
    
    // Estatísticas de pagamentos
    report.writeln('ESTATÍSTICAS DE PAGAMENTOS');
    report.writeln('-' * 30);
    report.writeln('Total de Pagamentos: ${payments.length}');
    report.writeln('Pagamentos Regulares: $regularPayments');
    report.writeln('Pagamentos em Atraso: $overduePayments');
    report.writeln('Pagamentos Antecipados: $advancePayments');
    report.writeln('');
    
    // Membros em atraso
    if (overdueMembersList.isNotEmpty) {
      report.writeln('MEMBROS EM ATRASO');
      report.writeln('-' * 30);
      for (var member in overdueMembersList) {
        final daysOverdue = member.nextPaymentDate != null 
            ? DateTime.now().difference(member.nextPaymentDate!).inDays 
            : 0;
        report.writeln('• ${member.name} - ${member.overdueMonths ?? 0} mensalidades - $daysOverdue dias');
      }
      report.writeln('');
    }
    
    // Últimos pagamentos
    if (recentPayments.isNotEmpty) {
      report.writeln('ÚLTIMOS PAGAMENTOS');
      report.writeln('-' * 30);
      for (var payment in recentPayments) {
        final paymentType = _getPaymentTypeText(payment.paymentType);
        report.writeln('• ${payment.memberName ?? 'Membro não encontrado'} - ${CurrencyFormatter.formatEuro(payment.amount)} - $paymentType - ${_formatDate(payment.paymentDate)}');
      }
      report.writeln('');
    }
    
    // Rodapé
    report.writeln('=' * 60);
    report.writeln('Relatório gerado automaticamente pelo sistema');
    report.writeln('Elostupi Store - Gestão de Mensalidades');
    report.writeln('=' * 60);
    
    return report.toString();
  }

  void _copyReportToClipboard(BuildContext context, String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      if (context.mounted) {
        SnackBarHelper.showCustom(
          context,
          message: 'Relatório copiado para a área de transferência',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showCustom(
          context,
          message: 'Não foi possível copiar o relatório',
          backgroundColor: Colors.red,
          icon: Icons.error,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }



  void _showDateRangeDialog(BuildContext context, PaymentController controller) {
    DateTime? startDate;
    DateTime? endDate;
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
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
                      color: Colors.blue[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, color: Colors.blue[700], size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filtrar por Período',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Text(
                                'Selecione o intervalo de datas',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[600],
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
                        // Data de início
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data de Início',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    startDate = date;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Colors.grey[600]),
                                    const SizedBox(width: 12),
                                    Text(
                                      startDate != null 
                                          ? _formatDate(startDate!)
                                          : 'Selecionar data',
                                      style: TextStyle(
                                        color: startDate != null ? Colors.black : Colors.grey[600],
                                        fontWeight: startDate != null ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Data de fim
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data de Fim',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? DateTime.now(),
                                  firstDate: startDate ?? DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    endDate = date;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Colors.grey[600]),
                                    const SizedBox(width: 12),
                                    Text(
                                      endDate != null 
                                          ? _formatDate(endDate!)
                                          : 'Selecionar data',
                                      style: TextStyle(
                                        color: endDate != null ? Colors.black : Colors.grey[600],
                                        fontWeight: endDate != null ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Opções rápidas
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Períodos Rápidos',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildQuickDateButton(
                                  'Este mês',
                                  () {
                                    final now = DateTime.now();
                                    setState(() {
                                      endDate = now;
                                      startDate = DateTime(now.year, now.month, 1);
                                    });
                                  },
                                ),
                                _buildQuickDateButton(
                                  'Mês passado',
                                  () {
                                    final now = DateTime.now();
                                    final lastMonth = DateTime(now.year, now.month - 1, 1);
                                    setState(() {
                                      endDate = DateTime(now.year, now.month, 0);
                                      startDate = lastMonth;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
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
                          onPressed: startDate != null && endDate != null
                              ? () {
                                  Get.back(); // Fechar o modal primeiro
                                  _applyDateFilter(startDate!, endDate!);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Aplicar Filtro'),
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

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.grey[700],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _applyDateFilter(DateTime startDate, DateTime endDate) {
    final memberController = Get.find<MemberController>();
    memberController.applyDateFilter(startDate, endDate);
  }

  void _clearDateFilter(MemberController memberController) {
    memberController.clearDateFilter();
  }
} 