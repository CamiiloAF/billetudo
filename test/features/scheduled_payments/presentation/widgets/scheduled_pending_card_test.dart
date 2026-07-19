import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_pending_card.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_pending_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scheduled_payment_fixtures.dart';

void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  List<PendingScheduledOccurrence> buildItems(int count) => [
        for (var i = 0; i < count; i++)
          buildPendingOccurrence(
            occurrence: buildOccurrence(id: 'occ-$i'),
            scheduledPayment: buildScheduledPayment(id: 'sp-$i'),
          ),
      ];

  testWidgets('con menos ítems que el máximo visible, no muestra overflow',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPendingCard(
          items: buildItems(2),
          onTapRow: (_) {},
          onReviewAll: () {},
        ),
      ),
    );

    expect(find.byType(ScheduledPendingRow), findsNWidgets(2));
    expect(find.textContaining('Ver los otros'), findsNothing);
  });

  testWidgets('con más ítems que maxVisibleRows, corta la lista y muestra el overflow',
      (tester) async {
    await tester.pumpWidget(
      appWith(
        ScheduledPendingCard(
          items: buildItems(6),
          onTapRow: (_) {},
          onReviewAll: () {},
        ),
      ),
    );

    expect(find.byType(ScheduledPendingRow), findsNWidgets(4));
    expect(find.text('Ver los otros 2 pendientes'), findsOneWidget);
  });

  testWidgets('tocar una fila visible llama onTapRow con esa ocurrencia',
      (tester) async {
    PendingScheduledOccurrence? tapped;
    final items = buildItems(2);

    await tester.pumpWidget(
      appWith(
        ScheduledPendingCard(
          items: items,
          onTapRow: (entry) => tapped = entry,
          onReviewAll: () {},
        ),
      ),
    );

    await tester.tap(find.byType(ScheduledPendingRow).first);
    await tester.pump();

    expect(tapped, items.first);
  });

  testWidgets('"Revisar todas" llama onReviewAll', (tester) async {
    var called = false;
    await tester.pumpWidget(
      appWith(
        ScheduledPendingCard(
          items: buildItems(1),
          onTapRow: (_) {},
          onReviewAll: () => called = true,
        ),
      ),
    );

    await tester.tap(find.text('Revisar todas'));
    await tester.pump();

    expect(called, isTrue);
  });
}
