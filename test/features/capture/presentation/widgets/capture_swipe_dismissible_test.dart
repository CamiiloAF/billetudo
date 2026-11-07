import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_swipe_action.dart';
import 'package:billetudo/features/capture/presentation/widgets/capture_swipe_dismissible.dart';
import 'package:billetudo/features/capture/presentation/widgets/pending_capture_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../capture_mocks.dart';

/// Swipe-to-discard (`IMs3M`/`bkNc1`): one direction only, an explicit
/// threshold, and the gesture must be reachable without it for screen readers.
void main() {
  CaptureReviewItem item() => CaptureReviewItem(
        capture: buildPendingCapture(merchantRaw: 'TIENDA D1'),
        accountName: 'Cuenta Nu',
        issuerName: 'Nu',
      );

  Widget appWith({
    required Future<void> Function() onDiscard,
  }) =>
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: CaptureSwipeDismissible(
                captureId: 'capture-1',
                onDiscard: onDiscard,
                child: PendingCaptureCard(item: item(), onTap: () {}),
              ),
            ),
          ),
        ),
      );

  testWidgets('crossing the threshold towards the start edge discards once',
      (tester) async {
    var discards = 0;
    await tester.pumpWidget(appWith(onDiscard: () async => discards++));

    await tester.drag(
      find.byType(PendingCaptureCard),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();

    expect(discards, 1);
  });

  testWidgets('a short drag does not discard', (tester) async {
    var discards = 0;
    await tester.pumpWidget(appWith(onDiscard: () async => discards++));

    // 350 * 0.35 = 122.5 logical px; -60 stays under the threshold.
    await tester.drag(
      find.byType(PendingCaptureCard),
      const Offset(-60, 0),
    );
    await tester.pumpAndSettle();

    expect(discards, 0);
  });

  testWidgets('dragging the other way does nothing', (tester) async {
    var discards = 0;
    await tester.pumpWidget(appWith(onDiscard: () async => discards++));

    await tester.drag(
      find.byType(PendingCaptureCard),
      const Offset(200, 0),
    );
    await tester.pumpAndSettle();

    expect(discards, 0);
  });

  testWidgets('the revealed action reads Discard, with the trash glyph',
      (tester) async {
    await tester.pumpWidget(appWith(onDiscard: () async {}));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PendingCaptureCard)),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CaptureSwipeAction), findsOneWidget);
    expect(find.text('Descartar'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('screen readers get the same action without the gesture',
      (tester) async {
    var discards = 0;
    await tester.pumpWidget(appWith(onDiscard: () async => discards++));

    final semantics = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byType(Dismissible),
            matching: find.byType(Semantics),
          )
          .first,
    );
    final matches = (semantics.properties.customSemanticsActions ?? const {})
        .entries
        .where((entry) => entry.key.label == 'Descartar captura')
        .toList();
    expect(matches, hasLength(1), reason: 'the swipe needs an accessible twin');

    matches.single.value();
    await tester.pump();
    expect(discards, 1);
  });
}
