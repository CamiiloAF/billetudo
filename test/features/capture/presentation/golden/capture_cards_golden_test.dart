import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/widgets/grouped_capture_card.dart';
import 'package:billetudo/features/capture/presentation/widgets/movement_pending_capture_card.dart';
import 'package:billetudo/features/capture/presentation/widgets/pending_capture_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';
import '../../capture_mocks.dart';

/// The ordinary/high-confidence capture card family: `skjlg` (Avisos centre),
/// `vRWd5` (movements ghost block, `oKokr` suggested-category chip) and
/// `RSizy` (wallet+bank grouped, `HU-07`). Kept in one file because the
/// three share the same 350px card context and most of their visual logic
/// is comparative — same amount attenuation, same "no suma a tu saldo"
/// signal, different chasis.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    Widget child,
    String name, {
    required Brightness brightness,
  }) async {
    await pumpGolden(
      tester,
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: 350, child: child),
        ),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('PendingCaptureCard with issuer line ($suffix)',
        (tester) async {
      await golden(
        tester,
        PendingCaptureCard(
          item: CaptureReviewItem(
            capture: buildPendingCapture(
              merchantRaw: 'TIENDA D1 SANTA ROSA',
              amountMinor: 5847000,
            ),
            accountName: 'Cuenta Nu',
            issuerName: 'Nu',
          ),
          onTap: () {},
        ),
        'pending_capture_card_with_issuer_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('PendingCaptureCard without a suggested account ($suffix)',
        (tester) async {
      await golden(
        tester,
        PendingCaptureCard(
          item: CaptureReviewItem(
            capture: buildPendingCapture(
              merchantRaw: 'EXITO CALLE 80',
              amountMinor: 4590000,
            ),
          ),
          onTap: () {},
        ),
        'pending_capture_card_no_account_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'MovementPendingCaptureCard with suggested category chip '
        '($suffix)', (tester) async {
      await golden(
        tester,
        MovementPendingCaptureCard(
          item: CaptureReviewItem(
            capture: buildPendingCapture(
              merchantRaw: 'TIENDA D1 SANTA ROSA',
              amountMinor: 5847000,
            ),
            accountName: 'Cuenta Nu',
            issuerName: 'Nu',
            suggestedCategoryName: 'Mercado',
          ),
          onTap: () {},
        ),
        'movement_pending_capture_card_with_chip_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'MovementPendingCaptureCard with no suggestion yet '
        '($suffix)', (tester) async {
      await golden(
        tester,
        MovementPendingCaptureCard(
          item: CaptureReviewItem(
            capture: buildPendingCapture(
              merchantRaw: 'EXITO CALLE 80',
              amountMinor: 4590000,
            ),
            accountName: 'Cuenta Nu',
            issuerName: 'Nu',
          ),
          onTap: () {},
        ),
        'movement_pending_capture_card_no_chip_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('GroupedCaptureCard names both issuers ($suffix)',
        (tester) async {
      await golden(
        tester,
        GroupedCaptureCard(
          item: CaptureReviewItem(
            capture: buildPendingCapture(
              merchantRaw: null,
              accountHint: '4417',
              amountMinor: 1870000,
            ),
            accountName: 'Bancolombia *4417',
            issuerName: 'Bancolombia',
            group: const CaptureGroupView(
              merchantRaw: 'CAFETERIA LA ESPIGA',
              walletIssuerName: 'Google Wallet',
              bankIssuerName: 'Bancolombia',
            ),
          ),
          onTap: () {},
        ),
        'grouped_capture_card_$suffix',
        brightness: brightness,
      );
    });
  }
}
