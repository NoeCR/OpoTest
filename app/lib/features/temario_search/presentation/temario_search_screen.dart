import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_decorations.dart';
import '../application/temario_search_service.dart';
import '../domain/temario_search.dart';
import 'temario_search_open.dart';

class TemarioSearchScreen extends StatefulWidget {
  const TemarioSearchScreen({super.key});

  @override
  State<TemarioSearchScreen> createState() => _TemarioSearchScreenState();
}

class _TemarioSearchScreenState extends State<TemarioSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  var _query = '';
  var _loading = false;
  TemarioSearchResults _results = TemarioSearchResults.empty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < temarioSearchMinQueryLength) {
      setState(() {
        _query = trimmed;
        _loading = false;
        _results = TemarioSearchResults.empty;
      });
      return;
    }
    setState(() {
      _query = trimmed;
      _loading = true;
    });
    _debounce = Timer(temarioSearchDebounce, () => _runSearch(trimmed));
  }

  Future<void> _runSearch(String query) async {
    final results = await context.read<TemarioSearchService>().search(query);
    if (!mounted || query != _query) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _open(TemarioSearchHit hit) async {
    await openTemarioSearchHit(context, hit);
  }

  @override
  Widget build(BuildContext context) {
    final contentReady = context.watch<AppState>().contentReady;

    return Scaffold(
      backgroundColor: AppTheme.pageBlue,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientHeader(
            title: 'Buscar',
            subtitle: 'Leyes, títulos, tests y preguntas',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              decoration: const InputDecoration(
                hintText: 'Ej. excedencia, silencio administrativo…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(child: _body(contentReady)),
        ],
      ),
    );
  }

  Widget _body(bool contentReady) {
    if (!contentReady) {
      return const _Message(
        text: 'Importa el temario desde Configuración para poder buscar.',
      );
    }
    if (_query.length < temarioSearchMinQueryLength) {
      return const _Message(
        text: 'Escribe al menos 2 letras para buscar en el temario.',
      );
    }
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return _Message(text: 'Sin coincidencias para «$_query».');
    }
    return TemarioSearchResultsView(
      results: _results,
      onSelect: _open,
    );
  }
}

class TemarioSearchResultsView extends StatelessWidget {
  const TemarioSearchResultsView({
    super.key,
    required this.results,
    required this.onSelect,
  });

  final TemarioSearchResults results;
  final ValueChanged<TemarioSearchHit> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (results.laws.isNotEmpty)
          _Section(
            label: 'Leyes',
            hits: results.laws,
            icon: Icons.menu_book_rounded,
            onSelect: onSelect,
          ),
        if (results.titles.isNotEmpty)
          _Section(
            label: 'Títulos',
            hits: results.titles,
            icon: Icons.topic_rounded,
            onSelect: onSelect,
          ),
        if (results.tests.isNotEmpty)
          _Section(
            label: 'Tests',
            hits: results.tests,
            icon: Icons.quiz_outlined,
            onSelect: onSelect,
          ),
        if (results.questions.isNotEmpty)
          _Section(
            label: 'Preguntas',
            hits: results.questions,
            icon: Icons.help_outline_rounded,
            onSelect: onSelect,
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.hits,
    required this.icon,
    required this.onSelect,
  });

  final String label;
  final List<TemarioSearchHit> hits;
  final IconData icon;
  final ValueChanged<TemarioSearchHit> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppDecorations.sectionLabel(context)),
          const SizedBox(height: 8),
          for (final hit in hits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(hit),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: AppDecorations.card(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(icon, color: AppTheme.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hit.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (hit.subtitle != null && hit.subtitle!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    hit.subtitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.black.withValues(alpha: 0.35)),
                        ],
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

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, height: 1.4),
        ),
      ),
    );
  }
}
