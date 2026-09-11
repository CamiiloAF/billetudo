import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/widgets/pending_captures_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';
import '../../capture_mocks.dart';

/// `vNjim` — the pinned "Pendientes de confirmar" block at the top of the
/// movements list (HU-04), reached through `PendingCapturesListSlot` in the
/// real page. Covers the block with a single card and with several, since
/// the header's count line and the 16pt gap between cards are its only
/// variable geometry.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  CaptureReviewItem item(String id, {String? suggestedCategoryName}) =>
      CaptureReviewItem(
        capture: buildPendingCapture(
          id: id,
          merchantRaw: 'TIENDA D1 SANTA ROSA',
          amountMinor: 5847000,
        ),
        accountName: 'Cuenta Nu',
        issuerName: 'Nu',
        suggestedCategoryName: suggestedCategoryName,
      );

  Future<void> golden(
    WidgetTester tester,
    List<CaptureReviewItem> items,
    String name, {
    required Brightness brightness,
  }) async {
    await pumpGolden(
      tester,
      SingleChildScrollView(
        child: PendingCapturesBlock(items: items, onTap: (_) {}),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pending_captures_block_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('a single pending capture ($suffix)', (tester) async {
      await golden(
        tester,
        [item('capture-1', suggestedCategoryName: 'Mercado')],
        'single_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'several pending captures stack with a fact count '
        '($suffix)', (tester) async {
      await golden(
        tester,
        [item('capture-1'), item('capture-2'), item('capture-3')],
        'multiple_$suffix',
        brightness: brightness,
      );
    });
  }
}
