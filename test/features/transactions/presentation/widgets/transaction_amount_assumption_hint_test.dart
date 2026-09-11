import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_amount_assumption_hint.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_amount_fixed_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The "monto supuesto" mark (`Va8F7`).
///
/// Without it someone can save $500.000 believing they confirmed $500, so the
/// assertions here are about the mark being *present and legible*, not about
/// it merely existing in the tree.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  late AppLocalizations l10n;
  late AppColors colors;

  Future<void> pump(WidgetTester tester, Widget child) async {
    setGoldenViewport(tester, goldenPhoneSize);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            colors = context.colors;
            return Align(alignment: Alignment.bottomCenter, child: child);
          },
        ),
        brightness: Brightness.light,
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget zone({String? amountSpokenText, int amountMinor = 2000000}) =>
      TransactionAmountFixedZone(
        type: TransactionType.expense,
        amountMinor: amountMinor,
        currency: 'COP',
        expanded: true,
        onExpand: () {},
        onCollapse: () {},
        onDigit: (_) {},
        onDecimal: () {},
        onOperator: (_) {},
        onEquals: () {},
        onBackspace: () {},
        onDictate: () {},
        amountSpokenText: amountSpokenText,
      );

  testWidgets('quotes the amount and the word it was inferred from',
      (tester) async {
    await pump(tester, zone(amountSpokenText: 'veinte'));

    expect(find.byType(TransactionAmountAssumptionHint), findsOneWidget);
    expect(
      find.text(l10n.captureVoiceAmountAssumption(r'$20.000', 'veinte')),
      findsOneWidget,
    );
  });

  testWidgets('is absent when the amount was not a guess', (tester) async {
    await pump(tester, zone());

    expect(find.byType(TransactionAmountAssumptionHint), findsNothing);
  });

  testWidgets(r'never uses $expense: a reading to check, not an error',
      (tester) async {
    await pump(tester, zone(amountSpokenText: 'veinte'));

    final label = tester.widget<Text>(
      find.descendant(
        of: find.byType(TransactionAmountAssumptionHint),
        matching: find.byType(Text),
      ),
    );
    expect(label.style?.color, colors.hintText);
    expect(label.style?.color, isNot(colors.expense));
    expect(label.style?.color, isNot(colors.expenseText));
  });

  testWidgets('the icon is info, not the mic of the Dictar pill right above it',
      (tester) async {
    await pump(tester, zone(amountSpokenText: 'veinte'));

    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(TransactionAmountAssumptionHint),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.icon?.codePoint, isNot(Icons.mic.codePoint));
    expect(icon.color, colors.hintText);
  });

  testWidgets(
      'a long amount plus a long quote wraps instead of overflowing — Pencil '
      'does not render this case, so the mockup string proves nothing',
      (tester) async {
    await pump(
      tester,
      zone(amountMinor: 150000000, amountSpokenText: 'mil quinientos'),
    );

    expect(tester.takeException(), isNull);
    final label = tester.widget<Text>(
      find.descendant(
        of: find.byType(TransactionAmountAssumptionHint),
        matching: find.byType(Text),
      ),
    );
    // Two lines, and no ellipsis: truncating would cut the figure or the
    // quote, which are the only two things the pill exists to show.
    expect(label.maxLines, 2);
    expect(label.overflow, isNull);
  });
}
