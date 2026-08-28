import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/temario_search/domain/temario_search.dart';

void main() {
  group('rankSearchFields', () {
    test('exacto gana a prefijo y contiene', () {
      expect(rankSearchFields('ce', ['CE', 'Constitución']), SearchMatchRank.exact);
      expect(rankSearchFields('constitucion', ['Constitución']), SearchMatchRank.exact);
    });

    test('prefijo gana a contiene', () {
      expect(rankSearchFields('const', ['Constitución']), SearchMatchRank.prefix);
      expect(rankSearchFields('silencio', ['silencio administrativo']), SearchMatchRank.prefix);
    });

    test('contiene si no es prefijo ni exacto', () {
      expect(
        rankSearchFields('administrativo', ['silencio administrativo']),
        SearchMatchRank.contains,
      );
      expect(rankSearchFields('titu', ['Constitución']), SearchMatchRank.contains);
    });

    test('sin coincidencia devuelve null', () {
      expect(rankSearchFields('ebep', ['Constitución', 'CE']), isNull);
    });
  });

  group('compareSearchHits', () {
    test('ordena exacto > prefijo > contiene, luego título', () {
      const exact = TemarioSearchHit(
        kind: TemarioSearchKind.test,
        id: '2',
        title: 'Silencio administrativo',
        rank: SearchMatchRank.exact,
      );
      const prefix = TemarioSearchHit(
        kind: TemarioSearchKind.test,
        id: '1',
        title: 'Silencio de la administración',
        rank: SearchMatchRank.prefix,
      );
      const contains = TemarioSearchHit(
        kind: TemarioSearchKind.test,
        id: '3',
        title: 'El silencio administrativo',
        rank: SearchMatchRank.contains,
      );

      final sorted = sortedSearchHits([contains, exact, prefix]);
      expect(sorted.map((h) => h.id), ['2', '1', '3']);
    });
  });

  group('sanitizeLikeQuery', () {
    test('quita comodines de LIKE', () {
      expect(sanitizeLikeQuery('100%_x'), '100x');
    });
  });
}
