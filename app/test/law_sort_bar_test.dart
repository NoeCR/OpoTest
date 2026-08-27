import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opotest/models/law_sort_mode.dart';
import 'package:opotest/widgets/law_sort_bar.dart';

void main() {
  testWidgets('el candado solo aparece en orden personalizado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LawSortBar(
            selected: LawSortMode.temario,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    expect(find.byIcon(Icons.lock_open_rounded), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LawSortBar(
            selected: LawSortMode.custom,
            customOrderLocked: true,
            onSelected: (_) {},
            onToggleCustomLock: () {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LawSortBar(
            selected: LawSortMode.custom,
            customOrderLocked: false,
            onSelected: (_) {},
            onToggleCustomLock: () {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);
  });
}
