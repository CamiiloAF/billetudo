import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_pending_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scheduled_payment_fixtures.dart';

/// AC9: omitir (skip) must only be reachable through the mandatory
/// confirmation/verification sheet, never a one-tap gesture directly on the
/// row (swipe-to-dismiss, long-press, or a dedicated skip icon).
void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  testWidgets('no envuelve la fila en un Dismissible (sin swipe-to-skip)',
      (tester) async {
    final entry = buildPendingOccurrence();

    await tester.pumpWidget(
      appWith(ScheduledPendingRow(entry: entry, onTap: () {})),
    );

    expect(find.byType(Dismissible), findsNothing);
  });

  testWidgets('no expone ningún ícono de omitir directamente en la fila',
      (tester) async {
    final entry = buildPendingOccurrence();

    await tester.pumpWidget(
      appWith(ScheduledPendingRow(entry: entry, onTap: () {})),
    );

    // The only interactive control on the row is the whole-row InkWell; no
    // separate IconButton (e.g. a skip/circle-slash icon) exists here — that
    // action only lives inside the confirmation sheet.
    expect(find.byType(IconButton), findsNothing);
    expect(find.byType(InkWell), findsOneWidget);
  });

  testWidgets(
      'el único gesto es un tap de toda la fila, que dispara onTap una vez',
      (tester) async {
    var tapCount = 0;
    final entry = buildPendingOccurrence();

    await tester.pumpWidget(
      appWith(
        ScheduledPendingRow(entry: entry, onTap: () => tapCount++),
      ),
    );

    await tester.tap(find.byType(ScheduledPendingRow));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('un swipe horizontal sobre la fila no dispara onTap (no hay skip de un toque)',
      (tester) async {
    var tapCount = 0;
    final entry = buildPendingOccurrence();

    await tester.pumpWidget(
      appWith(
        ScheduledPendingRow(entry: entry, onTap: () => tapCount++),
      ),
    );

    // A horizontal drag gesture (the shape a swipe-to-skip affordance would
    // take) must not resolve to the row's tap callback.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ScheduledPendingRow)),
    );
    await gesture.moveBy(const Offset(-250, 0));
    await gesture.up();
    await tester.pump();

    expect(tapCount, 0);
  });
}
