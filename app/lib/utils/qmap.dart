// Extrae IDs de test desde nodos qByTitle / qByChapter / qBySection / qByArticle.

Map<String, dynamic>? asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> mapsOf(dynamic value) {
  if (value is! List) return [];
  return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

List<String> testIdsFromQNode(Map<String, dynamic>? node, {bool includeSubLevel = false}) {
  if (node == null) return [];
  final ids = <String>[];
  final main = node['mainLevel'];
  if (main is List) {
    ids.addAll(main.map((e) => e.toString()));
  } else if (main is Map) {
    for (final v in main.values) {
      if (v is List) ids.addAll(v.map((e) => e.toString()));
    }
  }
  if (includeSubLevel) {
    final sub = node['subLevel'];
    if (sub is List) ids.addAll(sub.map((e) => e.toString()));
  }
  return ids;
}

List<String> testIdsFromQMap(dynamic qMap, String key, {bool includeSubLevel = false}) {
  final map = asStringMap(qMap);
  if (map == null) return [];
  return testIdsFromQNode(asStringMap(map[key]), includeSubLevel: includeSubLevel);
}

List<String> allTestIdsFromQMap(dynamic qMap, String key) {
  return testIdsFromQMap(qMap, key, includeSubLevel: true).toSet().toList();
}

String cleanText(dynamic value) => (value?.toString() ?? '').replaceAll('\r', '').trim();

class ProgressCounts {
  const ProgressCounts({required this.done, required this.total});

  final int done;
  final int total;

  bool get isEmpty => total <= 0;
  double get ratio => total <= 0 ? 0 : (done / total).clamp(0, 1);
  String get label => '$done/$total';
  bool get complete => total > 0 && done >= total;
}

ProgressCounts progressCounts(Iterable<String> testIds, Set<String> attempted) {
  final ids = testIds.toSet();
  return ProgressCounts(done: ids.where(attempted.contains).length, total: ids.length);
}

String progressLabel(Iterable<String> testIds, Set<String> attempted) {
  final counts = progressCounts(testIds, attempted);
  return counts.isEmpty ? '' : counts.label;
}

class ArticleTestGroup {
  const ArticleTestGroup({
    required this.articleId,
    required this.code,
    required this.order,
    required this.testIds,
  });

  final String articleId;
  final String code;
  final int order;
  final List<String> testIds;
}

List<ArticleTestGroup> articleTestGroups(Map<String, dynamic> payload) {
  final qByArticle = asStringMap(payload['qByArticle']) ?? {};
  final articles = mapsOf(payload['arArticles']);
  final groups = <ArticleTestGroup>[];
  for (final article in articles) {
    final id = article['id']?.toString() ?? '';
    if (id.isEmpty) continue;
    final ids = testIdsFromQMap(qByArticle, id);
    if (ids.isEmpty) continue;
    groups.add(
      ArticleTestGroup(
        articleId: id,
        code: article['code']?.toString() ?? 'Artículo',
        order: int.tryParse(article['order']?.toString() ?? '') ?? 0,
        testIds: ids,
      ),
    );
  }
  groups.sort((a, b) => a.order.compareTo(b.order));
  return groups;
}
