import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/presentation/widgets/numeric_keypad.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_amount_fixed_zone.dart';
import 'package:billetudo/features/transactions/presentation/widgets/voice_dictate_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The secondary voice trigger lives **inside** the amount `Zona Fija`
/// (`E1vEe7`), not above the form: the zone does not scroll, and dictating
/// fills the whole form rather than the visible field.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> pumpZone(
    WidgetTester tester, {
    required bool expanded,
    VoidCallback? onDictate,
  }) async {
    setGoldenViewport(tester, goldenPhoneSize);
    await tester.pumpWidget(
      wrapForGolden(
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TransactionAmountFixedZone(
              type: TransactionType.expense,
              amountMinor: 4500000,
              currency: 'COP',
              expanded: expanded,
              onExpand: () {},
              onCollapse: () {},
              onDigit: (_) {},
              onDecimal: () {},
              onOperator: (_) {},
              onEquals: () {},
              onBackspace: () {},
              onDictate: onDictate,
            ),
          ],
        ),
        brightness: Brightness.light,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the pill sits in the expanded header, next to the chevron',
      (tester) async {
    await pumpZone(tester, expanded: true, onDictate: () {});

    expect(find.byType(VoiceDictatePill), findsOneWidget);
    // Still the same zone: the keypad is untouched, the pill costs it nothing.
    expect(find.byType(NumericKeypad), findsOneWidget);
  });

  testWidgets('it carries a label, never the icon alone', (tester) async {
    late AppLocalizations l10n;
    setGoldenViewport(tester, goldenPhoneSize);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return Align(
              alignment: Alignment.topLeft,
              child: VoiceDictatePill(onPressed: () {}),
            );
          },
        ),
        brightness: Brightness.light,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.captureVoiceDictate), findsOneWidget);
  });

  testWidgets('tapping it asks to dictate, and nothing else', (tester) async {
    var taps = 0;
    await pumpZone(tester, expanded: true, onDictate: () => taps++);

    await tester.tap(find.byType(VoiceDictatePill));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('without the trigger wired the zone is exactly as it was',
      (tester) async {
    await pumpZone(tester, expanded: true);

    expect(find.byType(VoiceDictatePill), findsNothing);
  });

  testWidgets('the collapsed bar keeps its own shape (ofg07 has no pill)',
      (tester) async {
    await pumpZone(tester, expanded: false, onDictate: () {});

    expect(find.byType(VoiceDictatePill), findsNothing);
  });
}
