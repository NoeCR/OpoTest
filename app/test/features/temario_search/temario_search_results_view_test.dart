import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/features/temario_search/domain/temario_search.dart';
import 'package:opotest/features/temario_search/presentation/temario_search_screen.dart';

void main() {
  testWidgets('agrupa leyes, títulos y tests y notifica el toque', (tester) async {
    TemarioSearchHit? selected;
    const results = TemarioSearchResults(
      laws: [
        TemarioSearchHit(
          kind: TemarioSearchKind.law,
          id: '10',
          title: 'CE',
          subtitle: 'Constitución Española',
          rank: SearchMatchRank.exact,
        ),
      ],
      titles: [
        TemarioSearchHit(
          kind: TemarioSearchKind.title,
          id: '82',
          title: 'Derechos fundamentales',
          rank: SearchMatchRank.contains,
        ),
      ],
      tests: [
        TemarioSearchHit(
          kind: TemarioSearchKind.test,
          id: '1001',
          title: 'Test Constitución T1',
          rank: SearchMatchRank.prefix,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TemarioSearchResultsView(
            results: results,
            onSelect: (hit) => selected = hit,
          ),
        ),
      ),
    );

    expect(find.text('LEYES'), findsOneWidget);
    expect(find.text('TÍTULOS'), findsOneWidget);
    expect(find.text('TESTS'), findsOneWidget);
    expect(find.text('CE'), findsOneWidget);
    expect(find.text('Derechos fundamentales'), findsOneWidget);

    await tester.tap(find.text('Test Constitución T1'));
    expect(selected?.kind, TemarioSearchKind.test);
    expect(selected?.id, '1001');
  });
}
