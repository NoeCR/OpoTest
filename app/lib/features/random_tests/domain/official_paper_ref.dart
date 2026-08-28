/// Metadatos de una prueba real para el listado del simulacro.
class OfficialPaperRef {
  const OfficialPaperRef({
    required this.id,
    required this.name,
    required this.administration,
    this.year,
  });

  final String id;
  final String name;
  final String administration;
  final int? year;

  factory OfficialPaperRef.fromMeta({required String id, required String name}) {
    return OfficialPaperRef(
      id: id,
      name: name,
      administration: administrationOf(name),
      year: yearOf(name),
    );
  }

  static int? yearOf(String name) {
    final match = RegExp(r'\b(19|20)\d{2}\b').firstMatch(name);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  static String administrationOf(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('prueba real tai')) return 'Banco TAI (transcripciones)';
    if (lower.contains('inap') || lower.contains(' age') || lower.startsWith('age ') || lower.contains('administración del estado')) {
      return 'INAP / AGE';
    }
    final ayto = RegExp(r'ayuntamiento de ([^0-9·(]+)', caseSensitive: false).firstMatch(name);
    if (ayto != null) return 'Ayuntamiento de ${ayto.group(1)!.trim()}';
    final uni = RegExp(
      r'(?:univ(?:ersidad|ersitat)?\.?|universidad)(?: de | )([^0-9·(]+)',
      caseSensitive: false,
    ).firstMatch(name);
    if (uni != null) {
      var place = uni.group(1)!.trim();
      if (place.toLowerCase().startsWith('de ')) place = place.substring(3).trim();
      return 'Universidad de $place';
    }
    if (RegExp(r'\bupo\b', caseSensitive: false).hasMatch(name)) return 'Universidad Pablo de Olavide';
    if (RegExp(r'\bugr\b', caseSensitive: false).hasMatch(name)) return 'Universidad de Granada';
    if (RegExp(r'\bucm\b', caseSensitive: false).hasMatch(name)) return 'Universidad Complutense';
    if (RegExp(r'\buclm\b', caseSensitive: false).hasMatch(name)) return 'Universidad de Castilla-La Mancha';
    if (RegExp(r'\bcsic\b', caseSensitive: false).hasMatch(name)) return 'CSIC';
    if (lower.contains('senado')) return 'Senado';
    if (lower.contains('parlamento de andaluc')) return 'Parlamento de Andalucía';
    final dip = RegExp(r'diputaci[oó]n de ([^0-9·(]+)', caseSensitive: false).firstMatch(name);
    if (dip != null) return 'Diputación de ${dip.group(1)!.trim()}';
    if (lower.contains('jcyl') || lower.contains('jcl') || lower.contains('castilla y león') || lower.contains('castilla y leon')) {
      return 'Junta de Castilla y León';
    }
    if (RegExp(r'\bsas\b', caseSensitive: false).hasMatch(name) || lower.contains('servicio andaluz')) {
      return 'SAS (Andalucía)';
    }
    if (lower.contains('junta de andaluc')) return 'Junta de Andalucía';
    if (lower.contains('gva') || lower.contains('generalitat') || lower.contains('sanidad gva')) {
      return 'Generalitat Valenciana';
    }
    if (lower.contains('navarra') || RegExp(r'\bcfn\b', caseSensitive: false).hasMatch(name)) {
      return 'Comunidad Foral de Navarra';
    }
    if (lower.contains('extremadura')) return 'Junta de Extremadura';
    if (lower.contains('murcia')) return 'Región de Murcia';
    if (lower.contains('aragón') || lower.contains('aragon') || lower.contains('zaragoza')) {
      return 'Aragón';
    }
    if (lower.contains('castilla-la mancha') || lower.contains('jccm') || lower.contains('guadalajara')) {
      return 'Castilla-La Mancha';
    }
    return 'Otras administraciones';
  }

  static List<MapEntry<String, List<OfficialPaperRef>>> grouped(Iterable<OfficialPaperRef> papers) {
    final map = <String, List<OfficialPaperRef>>{};
    for (final paper in papers) {
      map.putIfAbsent(paper.administration, () => []).add(paper);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final yearCmp = (b.year ?? 0).compareTo(a.year ?? 0);
        if (yearCmp != 0) return yearCmp;
        return a.name.compareTo(b.name);
      });
    }
    final keys = map.keys.toList()..sort();
    return [for (final key in keys) MapEntry(key, map[key]!)];
  }
}
