import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/test_preferences.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_decorations.dart';
import '../application/random_test_service.dart';
import '../domain/official_paper_ref.dart';
import '../domain/random_test_constants.dart';
import 'random_test_launcher.dart';

class SimulacrumScreen extends StatefulWidget {
  const SimulacrumScreen({super.key, @visibleForTesting this.initialPapers});

  final List<OfficialPaperRef>? initialPapers;

  @override
  State<SimulacrumScreen> createState() => _SimulacrumScreenState();
}

class _SimulacrumScreenState extends State<SimulacrumScreen> {
  List<OfficialPaperRef>? _papers;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.initialPapers != null) {
      _papers = widget.initialPapers;
    } else {
      _loadPapers();
    }
  }

  Future<void> _loadPapers() async {
    try {
      final papers = await context.read<RandomTestService>().listOfficialPapers();
      if (!mounted) return;
      setState(() {
        _papers = papers;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _papers = const [];
        _loadError = 'No se pudieron cargar las pruebas reales.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<TestPreferences>();
    final papers = _papers;
    final selectedCount = papers == null
        ? 0
        : papers.where((p) => prefs.isSimulacrumPaperIncluded(p.id)).length;
    final canStart = papers != null && selectedCount > 0;

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      appBar: AppBar(
        title: const Text('Simulacro'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary.withValues(alpha: 0.9), AppTheme.cardDark.withValues(alpha: 0.95)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const Text(
                  'Examen a tamaño real con las pruebas de convocatoria que hayas importado. Elige cuáles entran en el pool. Tiempo fijo y sin corrección hasta el final.',
                  style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.35),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  label: 'Preguntas',
                  child: OptionChipRow<int>(
                    options: RandomTestConstants.simulacrumQuestionOptions,
                    selected: prefs.simulacrumQuestions,
                    onSelected: prefs.setSimulacrumQuestions,
                    labelBuilder: (n) => '$n',
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  label: 'Tiempo',
                  child: OptionChipRow<int>(
                    options: RandomTestConstants.simulacrumMinuteOptions,
                    selected: prefs.simulacrumMinutes,
                    onSelected: prefs.setSimulacrumMinutes,
                    labelBuilder: (m) => '$m min',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Los fallos restan 1 acierto, como en las pruebas oficiales. No usa el ajuste de Configuración.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
                ),
                const SizedBox(height: 20),
                _PaperCatalogCard(
                  papers: papers,
                  error: _loadError,
                  selectedCount: selectedCount,
                  prefs: prefs,
                ),
              ],
            ),
          ),
          Material(
            elevation: 8,
            color: AppTheme.pageBlue,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canStart
                        ? () => RandomTestLauncher.launchSimulacrum(
                              context,
                              includedTestIds: {
                                for (final paper in papers)
                                  if (prefs.isSimulacrumPaperIncluded(paper.id)) paper.id,
                              },
                            )
                        : null,
                    child: Text(
                      canStart
                          ? 'Empezar · ${prefs.simulacrumQuestions} preguntas · ${prefs.simulacrumMinutes} min'
                          : papers == null
                              ? 'Cargando pruebas…'
                              : 'Selecciona al menos una prueba',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperCatalogCard extends StatelessWidget {
  const _PaperCatalogCard({
    required this.papers,
    required this.error,
    required this.selectedCount,
    required this.prefs,
  });

  final List<OfficialPaperRef>? papers;
  final String? error;
  final int selectedCount;
  final TestPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      label: 'Pruebas en el pool',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (papers == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Cargando pruebas…', style: TextStyle(color: Colors.black54)),
            )
          else if (error != null)
            Text(error!, style: const TextStyle(color: Colors.black54))
          else if (papers!.isEmpty)
            const Text(
              'No hay pruebas reales importadas. En Configuración → Contenido → Importar, carga el JSON de pruebas reales.',
              style: TextStyle(color: Colors.black54, height: 1.35),
            )
          else ...[
            Text(
              '$selectedCount de ${papers!.length} seleccionadas',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton(
                  onPressed: prefs.includeAllSimulacrumPapers,
                  child: const Text('Todas'),
                ),
                TextButton(
                  onPressed: () => prefs.excludeSimulacrumPapers(papers!.map((p) => p.id)),
                  child: const Text('Ninguna'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final group in OfficialPaperRef.grouped(papers!))
              _AdminGroup(
                administration: group.key,
                papers: group.value,
                prefs: prefs,
              ),
          ],
        ],
      ),
    );
  }
}

class _AdminGroup extends StatelessWidget {
  const _AdminGroup({
    required this.administration,
    required this.papers,
    required this.prefs,
  });

  final String administration;
  final List<OfficialPaperRef> papers;
  final TestPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final includedCount = papers.where((p) => prefs.isSimulacrumPaperIncluded(p.id)).length;
    final allSelected = includedCount == papers.length;
    final noneSelected = includedCount == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          tristate: true,
          value: allSelected
              ? true
              : noneSelected
                  ? false
                  : null,
          onChanged: (_) {
            if (allSelected) {
              prefs.excludeSimulacrumPapers(papers.map((p) => p.id));
            } else {
              prefs.includeSimulacrumPapers(papers.map((p) => p.id));
            }
          },
          title: Text(
            administration,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        for (final paper in papers)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: prefs.isSimulacrumPaperIncluded(paper.id),
              onChanged: (value) => prefs.setSimulacrumPaperIncluded(paper.id, value ?? false),
              title: Text(paper.name, style: const TextStyle(fontSize: 14, height: 1.25)),
              subtitle: paper.year == null ? null : Text('${paper.year}'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
      ],
    );
  }
}
