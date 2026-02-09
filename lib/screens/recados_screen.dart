import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/recado_controller.dart';
import '../models/recado.dart';
import '../widgets/standard_appbar.dart';

class RecadosScreen extends StatelessWidget {
  const RecadosScreen({super.key});

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<RecadoController>();

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Recados e avisos',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.recados.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_add_outlined, size: 56, color: theme.colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  'Ainda não há recados',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use o botão + acima para adicionar',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          itemCount: controller.recados.length,
          itemBuilder: (context, index) {
            final r = controller.recados[index];
            final dias = r.diasRestantes;
            final urgente = r.alerta || (dias != null && dias <= 7);
            final accentColor = urgente ? Colors.orange : theme.colorScheme.tertiary;
            return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 4, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                urgente ? Icons.notifications_active_rounded : Icons.note_alt_outlined,
                                size: 18,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                r.titulo,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (urgente)
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Urgente',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, size: 20, color: theme.colorScheme.onSurfaceVariant),
                              padding: const EdgeInsets.all(4),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openForm(context, controller, recado: r);
                                } else if (value == 'delete') {
                                  _confirmDelete(context, controller, r);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (r.pessoa.isNotEmpty || r.instrucao.isNotEmpty || r.dataLimite != null || dias != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (r.pessoa.isNotEmpty || r.dataLimite != null || dias != null)
                                Row(
                                  children: [
                                    if (r.pessoa.isNotEmpty) ...[
                                      _metaChip(
                                        theme,
                                        Icons.person_outline_rounded,
                                        r.pessoa,
                                        theme.colorScheme.primaryContainer,
                                        theme.colorScheme.onPrimaryContainer,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (r.dataLimite != null || dias != null)
                                      _metaChip(
                                        theme,
                                        Icons.event_rounded,
                                        r.dataLimite != null
                                            ? '${_formatDate(r.dataLimite!)}${dias != null ? ' · ${dias == 1 ? '1 dia restante' : '$dias dias restantes'}' : ''}'
                                            : (dias == 1 ? '1 dia restante' : '$dias dias restantes'),
                                        theme.colorScheme.surfaceContainerHighest,
                                        theme.colorScheme.onSurfaceVariant,
                                      ),
                                  ],
                                ),
                              if (r.instrucao.isNotEmpty) ...[
                                if (r.pessoa.isNotEmpty || r.dataLimite != null || dias != null) const SizedBox(height: 8),
                                _InstrucoesExpandable(
                                  instrucao: r.instrucao,
                                  theme: theme,
                                  accentColor: accentColor,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
          },
        );
      }),
    );
  }

  void _openForm(BuildContext context, RecadoController controller, {Recado? recado}) {
    Get.to(() => _RecadoFormScreen(recado: recado));
  }

  void _confirmDelete(BuildContext context, RecadoController controller, Recado r) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar recado'),
        content: Text('Eliminar "${r.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              controller.remove(r.id);
              Get.back();
            },
            child: Text('Eliminar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(ThemeData theme, IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstrucoesExpandable extends StatefulWidget {
  final String instrucao;
  final ThemeData theme;
  final Color accentColor;

  const _InstrucoesExpandable({
    required this.instrucao,
    required this.theme,
    required this.accentColor,
  });

  @override
  State<_InstrucoesExpandable> createState() => _InstrucoesExpandableState();
}

class _InstrucoesExpandableState extends State<_InstrucoesExpandable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final accentColor = widget.accentColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            width: 3,
            color: accentColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Instruções',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.outline,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          size: 20,
                          color: accentColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _expanded ? 'Recolher' : 'Ver mais',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.instrucao,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.35,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: _expanded ? null : 2,
            overflow: _expanded ? null : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RecadoFormScreen extends StatefulWidget {
  final Recado? recado;

  const _RecadoFormScreen({this.recado});

  @override
  State<_RecadoFormScreen> createState() => _RecadoFormScreenState();
}

class _RecadoFormScreenState extends State<_RecadoFormScreen> {
  late final TextEditingController _tituloController;
  late final TextEditingController _pessoaController;
  late final TextEditingController _instrucaoController;
  DateTime? _dataLimite;
  bool _alerta = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recado;
    _tituloController = TextEditingController(text: r?.titulo ?? '');
    _pessoaController = TextEditingController(text: r?.pessoa ?? '');
    _instrucaoController = TextEditingController(text: r?.instrucao ?? '');
    _dataLimite = r?.dataLimite;
    _alerta = r?.alerta ?? false;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _pessoaController.dispose();
    _instrucaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<RecadoController>();
    final isEdit = widget.recado != null;
    final dataStr = _dataLimite != null
        ? '${_dataLimite!.day.toString().padLeft(2, '0')}/${_dataLimite!.month.toString().padLeft(2, '0')}/${_dataLimite!.year}'
        : null;

    return Scaffold(
      appBar: StandardAppBar(
        title: isEdit ? 'Editar recado' : 'Novo recado',
        backgroundColor: theme.colorScheme.primary,
        showBackButton: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: _saving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : TextButton(
                      onPressed: () => _save(controller),
                      child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _formCard(
              theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(theme, 'Título'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tituloController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Trabalho Exu',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _formCard(
              theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(theme, 'Responsável'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pessoaController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Luana',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _formCard(
              theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(theme, 'Instruções'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _instrucaoController,
                    decoration: InputDecoration(
                      hintText: 'Ex: 7 semanas não mexer',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _formCard(
              theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(theme, 'Data'),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dataLimite ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (date != null) setState(() => _dataLimite = date);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_rounded, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              dataStr ?? 'Escolher data',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: dataStr != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _formCard(
              theme,
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Marcar como alerta',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                    ),
                  ),
                  Switch(
                    value: _alerta,
                    onChanged: (v) => setState(() => _alerta = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formCard(ThemeData theme, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
        letterSpacing: 0.3,
      ),
    );
  }

  Future<void> _save(RecadoController controller) async {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) {
      Get.snackbar('Aviso', 'Indica um título.');
      return;
    }
    setState(() => _saving = true);
    try {
      final id = widget.recado?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final recado = Recado(
        id: id,
        titulo: titulo,
        pessoa: _pessoaController.text.trim(),
        instrucao: _instrucaoController.text.trim(),
        dataLimite: _dataLimite,
        alerta: _alerta,
      );
      if (widget.recado != null) {
        await controller.updateRecado(recado);
      } else {
        await controller.add(recado);
      }
      Get.back();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
