import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/user_facing_error.dart';
import '../../../widgets/app_decorations.dart';
import '../application/failed_questions_export_service.dart';
import '../domain/failed_question_item.dart';
import '../domain/failed_questions_range.dart';
import 'open_html_report.dart';

class FailedQuestionsExportScreen extends StatefulWidget {
  const FailedQuestionsExportScreen({super.key, this.initialPreset});

  final FailedQuestionsPreset? initialPreset;

  @override
  State<FailedQuestionsExportScreen> createState() => _FailedQuestionsExportScreenState();
}

class _FailedQuestionsExportScreenState extends State<FailedQuestionsExportScreen> {
  late FailedQuestionsPreset _preset = widget.initialPreset ?? FailedQuestionsPreset.lastDay;
  DateTime _customStart = DateTime.now().subtract(const Duration(days: 1));
  DateTime _customEnd = DateTime.now();
  DateTime? _lastExportAt;
  FailedQuestionsCollectResult? _preview;
  var _loading = true;
  var _exporting = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final userId = context.read<AppState>().activeUser?.id;
    if (userId == null) return;
    final last = await context.read<FailedQuestionsExportService>().lastExportAt(userId);
    if (!mounted) return;
    setState(() => _lastExportAt = last);
    await _refreshPreview();
  }

  FailedQuestionsRange? _rangeFor() {
    switch (_preset) {
      case FailedQuestionsPreset.lastDay:
        return FailedQuestionsRange.lastDay();
      case FailedQuestionsPreset.last7Days:
        return FailedQuestionsRange.last7Days();
      case FailedQuestionsPreset.sinceLastExport:
        final last = _lastExportAt;
        if (last == null) return null;
        return FailedQuestionsRange.sinceLastExport(lastExportAt: last);
      case FailedQuestionsPreset.custom:
        return FailedQuestionsRange.custom(startDate: _customStart, endDate: _customEnd);
    }
  }

  Future<void> _refreshPreview() async {
    final user = context.read<AppState>().activeUser;
    if (user == null) return;
    final range = _rangeFor();
    if (range == null) {
      setState(() {
        _preview = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final preview = await context.read<FailedQuestionsExportService>().preview(
            userId: user.id,
            range: range,
          );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _preview = null;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserFacingError.message(e, context: UserErrorContext.backup))),
      );
    }
  }

  Future<void> _selectDate({required bool start}) async {
    final initial = start ? _customStart : _customEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _customStart = picked;
        if (_customEnd.isBefore(_customStart)) _customEnd = _customStart;
      } else {
        _customEnd = picked;
        if (_customEnd.isBefore(_customStart)) _customStart = _customEnd;
      }
    });
    await _refreshPreview();
  }

  Future<void> _export() async {
    final user = context.read<AppState>().activeUser;
    if (user == null || _exporting) return;
    final range = _rangeFor();
    if (range == null) return;
    if ((_preview?.items.isEmpty ?? true) && (_preview?.skippedMissingTests ?? 0) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay fallos en este periodo.')),
      );
      return;
    }
    if (_preview?.items.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay fallos exportables en este periodo.')),
      );
      return;
    }

    setState(() => _exporting = true);
    final service = context.read<FailedQuestionsExportService>();
    try {
      final result = await service.export(user: user, range: range);
      if (!mounted) return;
      final opened = await openHtmlReport(result.filePath);
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró una app para abrir HTML. Instala un navegador e inténtalo de nuevo.'),
          ),
        );
        return;
      }
      await service.markExported(user.id);
      if (!mounted) return;
      setState(() => _lastExportAt = DateTime.now());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserFacingError.message(e, context: UserErrorContext.backup))),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final lastLabel = _lastExportAt == null
        ? 'Aún no has exportado fallos'
        : 'Última: ${_dateLabel(_lastExportAt!)} ${_lastExportAt!.hour.toString().padLeft(2, '0')}:${_lastExportAt!.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientHeader(
            title: 'Exportar fallos',
            subtitle: 'Informe HTML para estudiar en el navegador',
            showBack: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  label: 'Periodo',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _PresetChip(
                            label: 'Último día',
                            selected: _preset == FailedQuestionsPreset.lastDay,
                            onSelected: () {
                              setState(() => _preset = FailedQuestionsPreset.lastDay);
                              _refreshPreview();
                            },
                          ),
                          _PresetChip(
                            label: 'Últimos 7 días',
                            selected: _preset == FailedQuestionsPreset.last7Days,
                            onSelected: () {
                              setState(() => _preset = FailedQuestionsPreset.last7Days);
                              _refreshPreview();
                            },
                          ),
                          _PresetChip(
                            label: 'Desde la última exportación',
                            selected: _preset == FailedQuestionsPreset.sinceLastExport,
                            enabled: _lastExportAt != null,
                            onSelected: () {
                              setState(() => _preset = FailedQuestionsPreset.sinceLastExport);
                              _refreshPreview();
                            },
                          ),
                          _PresetChip(
                            label: 'Rango personalizado',
                            selected: _preset == FailedQuestionsPreset.custom,
                            onSelected: () {
                              setState(() => _preset = FailedQuestionsPreset.custom);
                              _refreshPreview();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(lastLabel, style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12)),
                      if (_preset == FailedQuestionsPreset.custom) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _selectDate(start: true),
                                child: Text('Desde ${_dateLabel(_customStart)}'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _selectDate(start: false),
                                child: Text('Hasta ${_dateLabel(_customEnd)}'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  label: 'Resumen',
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Text(
                          _preview == null
                              ? 'Elige un periodo con una exportación previa.'
                              : _preview!.items.isEmpty
                                  ? 'No hay fallos en este periodo.'
                                  : '${_preview!.items.length} pregunta(s) fallada(s)'
                                      '${_preview!.skippedMissingTests > 0 ? '\n${_preview!.skippedMissingTests} intento(s) omitidos (test ausente)' : ''}',
                          style: TextStyle(color: Colors.black.withValues(alpha: 0.7), height: 1.35),
                        ),
                ),
                const SizedBox(height: 20),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: AppDecorations.headerGradient,
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: _exporting || _loading || (_preview?.items.isEmpty ?? true) ? null : _export,
                    icon: const Icon(Icons.language_outlined),
                    label: Text(_exporting ? 'Preparando…' : 'ABRIR INFORME'),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Se abrirá el selector de apps. Elige un navegador para ver o guardar el informe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.5), fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? (_) => onSelected() : null,
      selectedColor: AppTheme.primary.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: enabled ? (selected ? AppTheme.primary : Colors.black87) : Colors.black38,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(color: selected && enabled ? AppTheme.primary : Colors.black12),
    );
  }
}
