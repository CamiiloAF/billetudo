import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/widgets/duplicate_compare_card.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';
import '../../capture_mocks.dart';

/// `EqRlj` — the possible-duplicate card, including its badge
/// (`v7U26p`/`DuplicateBadge`), its two asymmetric answers
/// (`Pm2sj`/`qkq49`/`DuplicateActionButton`) and the comparison strip
/// (`B1ydf`/`DuplicateCompareStrip`) — captured together since none of
/// those pieces ever renders detached from this card.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  CaptureReviewItem duplicateItem({required bool accountMatches}) =>
      CaptureReviewItem(
        capture: buildPendingCapture(
          merchantRaw: 'MERCADO DE LA SEMANA',
          amountMinor: 11525000,
        ),
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
        ),
      );

  Future<void> golden(
    WidgetTester tester,
    CaptureReviewItem item,
    String name, {
    required Brightness brightness,
  }) async {
    await pumpGolden(
      tester,
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 350,
            child: DuplicateCompareCard(
              item: item,
              onSame: () {},
              onDifferent: () {},
            ),
          ),
        ),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/duplicate_compare_card_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('same account, verdict names the coincidence ($suffix)',
        (tester) async {
      await golden(
        tester,
        duplicateItem(accountMatches: true),
        'same_account_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('different account, verdict drops "misma cuenta" ($suffix)',
        (tester) async {
      await golden(
        tester,
        duplicateItem(accountMatches: false),
        'different_account_$suffix',
        brightness: brightness,
      );
    });
  }
}
