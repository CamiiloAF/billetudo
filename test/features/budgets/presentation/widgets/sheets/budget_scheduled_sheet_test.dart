import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/empty_state.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scheduled_item.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_scheduled_row.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_scheduled_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  final items = [
    BudgetScheduledItem(
      id: 'sp-1@2025-07-05T00:00:00.000',
      scheduledPaymentId: 'sp-1',
      title: 'Netflix',
      accountName: 'Bancolombia',
      amountMinor: 4500000,
      currency: 'COP',
      date: DateTime(2025, 7, 5),
    ),
    BudgetScheduledItem(
      id: 'sp-1@2025-08-05T00:00:00.000',
      scheduledPaymentId: 'sp-1',
      title: 'Netflix',
      accountName: 'Bancolombia',
      amountMinor: 4500000,
      currency: 'COP',
      date: DateTime(2025, 8, 5),
    ),
  ];

  Future<void> pump(
    WidgetTester tester, {
    List<BudgetScheduledItem>? items,
    ValueChanged<String>? onOpenScheduledPayment,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BudgetScheduledSheet(
              items: items ?? const [],
              totalMinor: 9000000,
              currency: 'COP',
              onOpenScheduledPayment: onOpenScheduledPayment ?? (_) {},
            ),
          ),
        ),
      );

  testWidgets('lists one row per scheduled item', (tester) async {
    await pump(tester, items: items);

    expect(find.byType(BudgetScheduledRow), findsNWidgets(2));
  });

  testWidgets('the head shows the total amount', (tester) async {
    await pump(tester, items: items);

    expect(find.textContaining(r'$90.000'), findsOneWidget);
  });

  testWidgets(
      'an empty list reuses the shared EmptyState instead of a blank list',
      (tester) async {
    await pump(tester, items: const []);

    final context = tester.element(find.byType(BudgetScheduledSheet));
    expect(find.byType(EmptyState), findsOneWidget);
    expect(
      find.text(AppLocalizations.of(context).budgetScheduledSheetEmpty),
      findsOneWidget,
    );
  });

  testWidgets(
      'an empty list keeps the head to just the title (no hint repeating '
      'the empty message)', (tester) async {
    await pump(tester, items: const []);

    final context = tester.element(find.byType(BudgetScheduledSheet));
    expect(
      find.text(AppLocalizations.of(context).budgetScheduledSheetTitle),
      findsOneWidget,
    );
    expect(find.textContaining('reservado'), findsNothing);
  });

  testWidgets(
      'tapping a row opens its template detail via scheduledPaymentId, not '
      "the occurrence's synthetic id", (tester) async {
    String? openedId;
    await pump(
      tester,
      items: items,
      onOpenScheduledPayment: (id) => openedId = id,
    );

    await tester.tap(find.text('Netflix').first);
    await tester.pumpAndSettle();

    expect(openedId, 'sp-1');
  });

  testWidgets(
      'tapping a row closes the sheet and defers onOpenScheduledPayment to '
      'the next frame instead of calling it in the same tick, so the pop '
      "and the destination's push never compete as two Navigator "
      'transitions on the same frame', (tester) async {
    final callOrder = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BudgetScheduledSheet.show(
                context,
                items: items,
                totalMinor: 9000000,
                currency: 'COP',
                onOpenScheduledPayment: (id) => callOrder.add('opened:$id'),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetScheduledSheet), findsOneWidget);

    await tester.tap(find.text('Netflix').first);

    // Right after the tap (still no frame pumped): the pop has been
    // requested but the callback must not have fired yet — that is the
    // deferral this fix relies on.
    expect(callOrder, isEmpty);

    // A single frame is enough for the deferred postFrameCallback to run,
    // well before the sheet's close animation (and thus the destination
    // page's `pop()`-adjacent push) is done settling.
    await tester.pump();
    expect(callOrder, ['opened:sp-1']);

    await tester.pumpAndSettle();

    // The sheet must be gone once everything settles: the callback firing
    // one frame later must not leave the modal route stuck on top of the
    // destination push.
    expect(find.byType(BudgetScheduledSheet), findsNothing);
    expect(callOrder, ['opened:sp-1']);
  });
}
