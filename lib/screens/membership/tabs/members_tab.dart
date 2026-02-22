import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/member_controller.dart';
import '../../../core/currency_formatter.dart';
import '../widgets/membership_shared_widgets.dart';
import '../widgets/membership_dialogs.dart';
import '../membership_utils.dart';

class MembersTab extends StatefulWidget {
  final MemberController controller;

  const MembersTab({super.key, required this.controller});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      widget.controller.searchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorMessage.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 56,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage.value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => controller.loadMembers(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      }

      final stats = controller.getStatistics();
      final filteredMembers = controller.filteredMembers;

      return Column(
        children: [
          // Cards de estatísticas
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: MembershipStatCard(
                    title: 'Total',
                    value: stats['total'].toString(),
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MembershipStatCard(
                    title: 'Ativos',
                    value: stats['active'].toString(),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MembershipStatCard(
                    title: 'Em atraso',
                    value: stats['overdue'].toString(),
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),

          // Botões de filtro rápido
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => controller.refreshData(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Atualizar'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => controller.loadOverdueMembers(),
                    icon: const Icon(Icons.warning_amber, size: 18),
                    label: const Text('Em atraso'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => controller.loadActiveMembers(),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Ativos'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Campo de busca
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar membros...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          controller.searchQuery.value = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Lista de membros
          Expanded(
            child: filteredMembers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum membro encontrado',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      // Cache results of overdue check to avoid repeated calculations
                      final isOverdue = controller.isMemberOverdue(member);
                      final daysOverdue = isOverdue
                          ? controller.getDaysOverdue(member)
                          : 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withValues(
                                alpha: 0.06,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: theme.colorScheme.shadow.withValues(
                                alpha: 0.02,
                              ),
                              blurRadius: 2,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => MembershipDialogs.showMemberDetails(
                              context,
                              member,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: !member.isActive
                                        ? theme.colorScheme.outline
                                        : (isOverdue
                                              ? theme.colorScheme.error
                                              : Colors.green),
                                    child: Text(
                                      member.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              member.name,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: !member.isActive
                                                        ? theme
                                                              .colorScheme
                                                              .onSurfaceVariant
                                                        : theme
                                                              .colorScheme
                                                              .onSurface,
                                                  ),
                                            ),
                                            if (!member.isActive) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: theme
                                                        .colorScheme
                                                        .outlineVariant,
                                                  ),
                                                ),
                                                child: Text(
                                                  'INATIVO',
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(
                                              CurrencyFormatter.formatEuro(
                                                member.monthlyFee,
                                              ),
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(width: 14),
                                            if (member.nextPaymentDate != null)
                                              Row(
                                                children: [
                                                  Icon(
                                                    isOverdue
                                                        ? Icons.warning_amber
                                                        : Icons.calendar_today,
                                                    color: isOverdue
                                                        ? theme
                                                              .colorScheme
                                                              .error
                                                        : Colors.green,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    MembershipUtils.formatDate(
                                                      member.nextPaymentDate!,
                                                    ),
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: isOverdue
                                                              ? theme
                                                                    .colorScheme
                                                                    .error
                                                              : theme
                                                                    .colorScheme
                                                                    .onSurfaceVariant,
                                                          fontWeight: isOverdue
                                                              ? FontWeight.w600
                                                              : FontWeight
                                                                    .normal,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        if (isOverdue) ...[
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                color: theme.colorScheme.error,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$daysOverdue dias',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .error,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              if (member.overdueMonths !=
                                                      null &&
                                                  member.overdueMonths! >
                                                      0) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  '• ${member.overdueMonths} mens.',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .error,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                              if (member.totalOverdue != null &&
                                                  member.totalOverdue! > 0) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  '• ${CurrencyFormatter.formatEuro(member.totalOverdue!)}',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .error,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: member.isActive
                                            ? () =>
                                                  MembershipDialogs.showPaymentDialog(
                                                    context,
                                                    member,
                                                  )
                                            : null,
                                        icon: const Icon(Icons.payment),
                                        color: Colors.green,
                                        tooltip: 'Pagamento',
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            MembershipDialogs.showEditMemberDialog(
                                              context,
                                              member,
                                              controller,
                                            ),
                                        icon: const Icon(Icons.edit),
                                        color: theme.colorScheme.primary,
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            MembershipDialogs.showDeleteConfirmation(
                                              context,
                                              member,
                                              controller,
                                            ),
                                        icon: const Icon(Icons.delete_outline),
                                        color: theme.colorScheme.error,
                                        tooltip: 'Excluir',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
}
