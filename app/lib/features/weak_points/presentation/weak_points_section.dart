import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../navigation/app_navigation.dart';
import '../../../screens/laws_screen.dart';
import '../../../state/app_state.dart';
import '../../../state/progress_reload.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_decorations.dart';
import '../../../widgets/topic_progress_card.dart';
import '../../temario_search/domain/temario_search.dart';
import '../../temario_search/presentation/temario_search_open.dart';
import '../application/weak_points_service.dart';
import '../domain/weak_points.dart';

class WeakPointsSection extends StatefulWidget {
  const WeakPointsSection({super.key});

  @override
  State<WeakPointsSection> createState() => _WeakPointsSectionState();
}

class _WeakPointsSectionState extends State<WeakPointsSection> with ProgressReload {
  WeakPointsScope _scope = WeakPointsScope.laws;
  WeakPointsSort _sort = WeakPointsSort.weakest;
  List<WeakTopic>? _topics;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void onProgressChanged() {
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AppState>().activeUser?.id;
    if (userId == null) return;
    final topics = await context.read<WeakPointsService>().topicsFor(
          userId: userId,
          scope: _scope,
          sort: _sort,
        );
    if (!mounted) return;
    setState(() {
      _topics = topics;
      _loading = false;
    });
  }

  Future<void> _open(WeakTopic topic) async {
    if (topic.scope == WeakPointsScope.laws) {
      await context.pushPage(
        LawContentScreen(
          lawId: topic.lawId,
          lawCode: topic.lawCode ?? topic.title,
          lawName: topic.lawName ?? topic.subtitle ?? topic.title,
        ),
      );
    } else {
      await openTemarioSearchHit(
        context,
        TemarioSearchHit(
          kind: TemarioSearchKind.title,
          id: topic.titleId ?? topic.id,
          title: topic.title,
          rank: SearchMatchRank.contains,
          lawId: topic.lawId,
          lawCode: topic.lawCode,
          lawName: topic.lawName,
          titleId: topic.titleId ?? topic.id,
        ),
      );
    }
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('PUNTOS DÉBILES', style: AppDecorations.sectionLabel(context)),
        const SizedBox(height: 8),
        OptionChipRow<WeakPointsScope>(
          options: WeakPointsScope.values,
          selected: _scope,
          labelBuilder: (s) => s.label,
          onSelected: (scope) {
            setState(() {
              _scope = scope;
              _loading = true;
            });
            _load();
          },
        ),
        const SizedBox(height: 8),
        OptionChipRow<WeakPointsSort>(
          options: WeakPointsSort.values,
          selected: _sort,
          labelBuilder: (s) => s.label,
          onSelected: (sort) {
            setState(() {
              _sort = sort;
              if (_topics != null) {
                final next = [..._topics!];
                sortWeakTopics(next, sort);
                _topics = next;
              }
            });
          },
        ),
        const SizedBox(height: 12),
        if (_loading && _topics == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_topics == null || _topics!.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Haz tests del temario para ver aquí las leyes y títulos más flojos. Los tests aleatorios no cuentan.',
              style: TextStyle(color: Colors.black54, height: 1.35),
            ),
          )
        else
          for (final topic in _topics!)
            _WeakTopicTile(topic: topic, onTap: () => _open(topic)),
      ],
    );
  }
}

class _WeakTopicTile extends StatelessWidget {
  const _WeakTopicTile({required this.topic, required this.onTap});

  final WeakTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = topic.stats.lastPercent;
    final color = last == null ? Colors.black26 : progressTrafficColor(last / 100);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: AppDecorations.card(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        if (topic.subtitle != null && topic.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            topic.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Media ${topic.stats.avgLabel} · ${topic.stats.attempts} '
                          '${topic.stats.attempts == 1 ? 'intento' : 'intentos'}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    topic.stats.lastLabel,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: last == null ? Colors.black45 : AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
