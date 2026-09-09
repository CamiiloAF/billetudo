import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/widgets/duplicate_action_button.dart';
import 'package:billetudo/features/capture/presentation/widgets/duplicate_compare_card.dart';
import 'package:billetudo/features/capture/presentation/widgets/duplicate_compare_strip.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../capture_mocks.dart';

/// `EqRlj` — the possible-duplicate card. The app never merges nor discards
/// on its own; these tests protect the two-branch, no-default shape of that
/// promise.
void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SizedBox(width: 350, child: child)),
      );

  CaptureReviewItem duplicateItem({bool accountMatches = true}) =>
      CaptureReviewItem(
        capture: buildPendingCapture(amountMinor: 11525000),
        accountName: 'Cuenta Nu',
        issuerName: 'Nu',
        duplicate: CaptureDuplicateView(
          transactionId: 'tx-1',
          amountMinor: 11525000,
          currency: 'COP',
          type: TransactionType.expense,
          date: DateTime(2026, 9, 1, 11, 9),
          accountMatches: accountMatches,
          title: 'Mercado de la semana',
          accountName: 'Cuenta Nu',
          categoryName: 'Mercado',
          categoryIcon: 'shopping-cart',
          categoryColor: 'mint',
        ),
      );

  testWidgets('offers two asymmetric answers, never a default', (tester) async {
    await tester.pumpWidget(
      appWith(
        DuplicateCompareCard(
          item: duplicateItem(),
          onSame: () {},
          onDifferent: () {},
        ),
      ),
    );

    final buttons = tester
        .widgetList<DuplicateActionButton>(find.byType(DuplicateActionButton))
        .toList();
    expect(buttons, hasLength(2));
    expect(find.text('Es la misma'), findsOneWidget);
    expect(find.text('Es otra compra'), findsOneWidget);

    final colors = AppTheme.light().extension<AppColors>()!;
    final same = buttons.firstWhere(
      (b) => b.variant == DuplicateActionVariant.same,
    );
    final different = buttons.firstWhere(
      (b) => b.variant == DuplicateActionVariant.different,
    );
    expect(same.variant, isNot(different.variant));

    // "Es otra compra" writes nothing on its own, so it carries the solid
    // primary treatment; "Es la misma" executes (a discard), so it stays
    // muted — the color never pushes the user towards the destructive path.
    final sameLabel = tester.widget<Text>(find.text('Es la misma'));
    final otherLabel = tester.widget<Text>(find.text('Es otra compra'));
    expect(sameLabel.style?.color, colors.textPrimary);
    expect(otherLabel.style?.color, colors.onPrimary);
  });

  testWidgets('marks the duplicate in amber, never in the expense red',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        DuplicateCompareCard(
          item: duplicateItem(),
          onSame: () {},
          onDifferent: () {},
        ),
      ),
    );

    final colors = AppTheme.light().extension<AppColors>()!;
    final label = tester.widget<Text>(find.text('Posible duplicado'));
    expect(label.style?.color, colors.amberText);
    expect(label.style?.color, isNot(colors.expense));
    expect(label.style?.color, isNot(colors.expenseText));
  });

  testWidgets('names the existing category in text, not just a glyph',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        DuplicateCompareCard(
          item: duplicateItem(),
          onSame: () {},
          onDifferent: () {},
        ),
      ),
    );

    expect(find.textContaining('Mercado'), findsWidgets);
    expect(find.textContaining('Ya registrado'), findsOneWidget);
  });

  testWidgets('the verdict line drops "misma cuenta" when the account misses',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        DuplicateCompareCard(
          item: duplicateItem(accountMatches: false),
          onSame: () {},
          onDifferent: () {},
        ),
      ),
    );

    expect(find.textContaining('misma cuenta'), findsNothing);
    expect(find.textContaining('Mismo monto'), findsOneWidget);
  });

  testWidgets('the compared movement is not tappable', (tester) async {
    await tester.pumpWidget(
      appWith(
        DuplicateCompareCard(
          item: duplicateItem(),
          onSame: () {},
          onDifferent: () {},
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(DuplicateCompareStrip),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets(
      'exactly two tap targets exist — the buttons, never the whole chasis',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        DuplicateCompareCard(
          item: duplicateItem(),
          onSame: () {},
          onDifferent: () {},
        ),
      ),
    );

    expect(find.byType(InkWell), findsNWidgets(2));
  });

  testWidgets('neither answer fires on its own', (tester) async {
    var same = 0;
    var different = 0;
    await tester.pumpWidget(
      appWith(
        DuplicateCompareCard(
          item: duplicateItem(),
          onSame: () => same++,
          onDifferent: () => different++,
        ),
      ),
    );
    await tester.pump();

    expect(same, 0);
    expect(different, 0);
  });
}
