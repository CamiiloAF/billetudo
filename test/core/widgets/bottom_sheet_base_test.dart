import 'dart:async';

import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression for the Patrol failure `Found 0 widgets with text "¡Felicidades!
  // Ya no debes nada"`: a sheet's own save can trigger a second sheet to open
  // on the same root navigator (e.g. `DebtDetailPage._handleSideEffects`
  // opening `DebtCelebrationSheet` right after `DebtPaymentSheet`/
  // `DebtUpdateBalanceSheet` settles a debt). If the second sheet lands on top
  // of the stack *before* the first sheet's own "saved" listener runs, a plain
  // `Navigator.pop()` would pop whichever route is on top — silently
  // dismissing the second sheet instead of the first. `BottomSheetBase.dismiss`
  // must remove the caller's own route regardless of stack position.
  group('BottomSheetBase.dismiss', () {
    // `BottomSheetBase.show`'s future only completes once the sheet is
    // dismissed, so it must not be awaited here — the point of this helper is
    // to get the sheet's own `BuildContext` while it is still open.
    Future<BuildContext> openSheet(
      WidgetTester tester, {
      required String label,
    }) async {
      late BuildContext sheetContext;
      unawaited(
        BottomSheetBase.show<void>(
          tester.element(find.byType(Scaffold)),
          builder: (context) {
            sheetContext = context;
            return Text(label);
          },
        ),
      );
      await tester.pumpAndSettle();
      return sheetContext;
    }

    Future<void> pumpHost(WidgetTester tester) => tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: SizedBox.shrink()),
          ),
        );

    testWidgets(
        'pops its own route when it is still the topmost route (normal save)',
        (tester) async {
      await pumpHost(tester);
      final context = await openSheet(tester, label: 'sheet-a');
      expect(find.text('sheet-a'), findsOneWidget);

      BottomSheetBase.dismiss(context);
      await tester.pumpAndSettle();

      expect(find.text('sheet-a'), findsNothing);
    });

    testWidgets(
        'removes its own route without touching a second sheet pushed on top '
        '(the celebration-sheet race)', (tester) async {
      await pumpHost(tester);
      final contextA = await openSheet(tester, label: 'sheet-a');
      expect(find.text('sheet-a'), findsOneWidget);

      // A second sheet opens on top before sheet A's own "saved" listener
      // gets to run — the exact ordering the real device race produced.
      await openSheet(tester, label: 'sheet-b');
      expect(find.text('sheet-a'), findsOneWidget);
      expect(find.text('sheet-b'), findsOneWidget);

      BottomSheetBase.dismiss(contextA);
      await tester.pumpAndSettle();

      // Sheet A is gone, but sheet B — the one that matters, the celebration
      // — survives untouched.
      expect(find.text('sheet-a'), findsNothing);
      expect(find.text('sheet-b'), findsOneWidget);
    });
  });
}
