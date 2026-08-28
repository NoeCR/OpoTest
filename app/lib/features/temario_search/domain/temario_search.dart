/// Ranking de coincidencias: nombre exacto > prefijo > contiene.
enum SearchMatchRank { exact, prefix, contains }

enum TemarioSearchKind { law, title, test, question }

class TemarioSearchHit {
  const TemarioSearchHit({
    required this.kind,
    required this.id,
    required this.title,
    required this.rank,
    this.subtitle,
    this.lawId,
    this.lawCode,
    this.lawName,
    this.titleId,
    this.testId,
    this.questionIndex,
  });

  final TemarioSearchKind kind;
  final String id;
  final String title;
  final SearchMatchRank rank;
  final String? subtitle;
  final String? lawId;
  final String? lawCode;
  final String? lawName;
  final String? titleId;
  final String? testId;
  final int? questionIndex;
}

class TemarioSearchResults {
  const TemarioSearchResults({
    this.laws = const [],
    this.titles = const [],
    this.tests = const [],
    this.questions = const [],
  });

  static const empty = TemarioSearchResults();

  final List<TemarioSearchHit> laws;
  final List<TemarioSearchHit> titles;
  final List<TemarioSearchHit> tests;
  final List<TemarioSearchHit> questions;

  bool get isEmpty =>
      laws.isEmpty && titles.isEmpty && tests.isEmpty && questions.isEmpty;

  int get total => laws.length + titles.length + tests.length + questions.length;
}

const temarioSearchMinQueryLength = 2;
const temarioSearchQuestionLimit = 30;
const temarioSearchDebounce = Duration(milliseconds: 250);

const _accentFold = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
};

String normalizeSearchQuery(String raw) {
  final lower = raw.trim().toLowerCase();
  if (lower.isEmpty) return lower;
  final buffer = StringBuffer();
  for (final unit in lower.runes) {
    final char = String.fromCharCode(unit);
    buffer.write(_accentFold[char] ?? char);
  }
  return buffer.toString();
}

/// Quita comodines de LIKE para no convertir la consulta en un patrón.
String sanitizeLikeQuery(String query) =>
    query.replaceAll(RegExp(r'[%_\\]'), '');

String likeContainsPattern(String query) => '%${sanitizeLikeQuery(query)}%';

SearchMatchRank? rankSearchFields(String query, Iterable<String> fields) {
  if (query.isEmpty) return null;
  SearchMatchRank? best;
  for (final field in fields) {
    final value = normalizeSearchQuery(field);
    if (value.isEmpty) continue;
    if (value == query) return SearchMatchRank.exact;
    if (value.startsWith(query)) {
      best = SearchMatchRank.prefix;
    } else if (best == null && value.contains(query)) {
      best = SearchMatchRank.contains;
    }
  }
  return best;
}

int compareSearchHits(TemarioSearchHit a, TemarioSearchHit b) {
  final byRank = a.rank.index.compareTo(b.rank.index);
  if (byRank != 0) return byRank;
  final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  if (byTitle != 0) return byTitle;
  return a.id.compareTo(b.id);
}

List<TemarioSearchHit> sortedSearchHits(Iterable<TemarioSearchHit> hits) {
  final list = hits.toList();
  list.sort(compareSearchHits);
  return list;
}
