import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_swipe_dismissible.dart';
import 'package:billetudo/features/capture/presentation/widgets/pending_capture_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';
import '../../capture_mocks.dart';

/// `IMs3M` (claro) / `bkNc1` (oscuro): the swipe state of a capture card —
/// the action revealed behind it, captured mid-gesture so the goldens are the
/// deterministic reference for `/design-fidelity-check`.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  CaptureReviewItem item() => CaptureReviewItem(
        capture: buildPendingCapture(
          merchantRaw: 'TIENDA D1 SANTA ROSA',
          amountMinor: 5847000,
        ),
        accountName: 'Cuenta Nu',
        issuerName: 'Nu',
      );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('capture card swiped reveals the discard action ($suffix)',
        (tester) async {
      await pumpGolden(
        tester,
        SizedBox(
          width: 350,
          child: CaptureSwipeDismissible(
            captureId: 'capture-1',
            onDiscard: () async {},
            child: PendingCaptureCard(item: item(), onTap: () {}),
          ),
        ),
        brightness: brightness,
      );

      // Hold the card mid-swipe: no release, so no dismissal can interfere.
      // Moves are incremental with a frame between them — a single jump is
      // not enough for the drag to be picked up and painted.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PendingCaptureCard)),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-70, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/capture_swipe_action_$suffix.png'),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });
  }
}
