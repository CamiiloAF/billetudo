import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scheduled_item.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_scheduled_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  final item = BudgetScheduledItem(
    id: 'sp-1@2025-07-28T00:00:00.000',
    scheduledPaymentId: 'sp-1',
    note: 'Netflix',
    accountName: 'Bancolombia',
    amountMinor: 4500000,
    currency: 'COP',
    date: DateTime(2025, 7, 28),
    categoryIcon: 'tv',
    categoryColor: 'sky',
  );

  Future<void> pump(
    WidgetTester tester, {
    ValueChanged<String>? onTap,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BudgetScheduledRow(item: item, onTap: onTap ?? (_) {}),
          ),
        ),
      );

  testWidgets('shows the title and the unsigned amount, no minus sign',
      (tester) async {
    await pump(tester);

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.textContaining(r'$45.000'), findsOneWidget);
    expect(find.textContaining('-\$45.000'), findsNothing);
  });

  testWidgets(
      'item 19: with no note the title is the generic label, never the '
      'category', (tester) async {
    final noNote = BudgetScheduledItem(
      id: 'sp-2@2025-07-28T00:00:00.000',
      scheduledPaymentId: 'sp-2',
      note: null,
      accountName: 'Bancolombia',
      amountMinor: 4500000,
      currency: 'COP',
      date: DateTime(2025, 7, 28),
      categoryIcon: 'tv',
      categoryColor: 'sky',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BudgetScheduledRow(item: noNote, onTap: (_) {}),
        ),
      ),
    );

    expect(find.text('Pago programado'), findsOneWidget);
  });

  testWidgets('the amount renders in the secondary text color, not primary',
      (tester) async {
    await pump(tester);

    const colors = AppColors.light;
    final amountText = tester.widget<Text>(find.textContaining(r'$45.000'));
    expect(amountText.style?.color, colors.textSecondary);
    expect(amountText.style?.color, isNot(colors.textPrimary));
  });

  testWidgets(
      'the subtitle reads "Próximo: fecha · cuenta", date before account',
      (tester) async {
    await pump(tester);

    final subtitle = tester.widget<Text>(find.textContaining('Próximo:'));
    final data = subtitle.data!;
    expect(data.startsWith('Próximo:'), isTrue);
    final proximoIndex = data.indexOf('Próximo:');
    final accountIndex = data.indexOf('Bancolombia');
    expect(accountIndex, greaterThan(proximoIndex));
    expect(data, contains('Bancolombia'));
    expect(data, contains('jul'));
  });

  testWidgets('shows the recurrence badge overlaid on the category icon wrap',
      (tester) async {
    await pump(tester);

    expect(find.byIcon(LucideIcons.repeat), findsOneWidget);

    // The badge sits inside a Positioned within the icon-wrap's own Stack —
    // find the Stack that is an ancestor of the repeat icon.
    final badgeStackFinder = find.ancestor(
      of: find.byIcon(LucideIcons.repeat),
      matching: find.byType(Stack),
    );
    expect(badgeStackFinder, findsOneWidget);

    final positioned = tester.widget<Positioned>(
      find.ancestor(
        of: find.byIcon(LucideIcons.repeat),
        matching: find.byType(Positioned),
      ),
    );
    expect(positioned.left, 28);
    expect(positioned.top, 28);
  });

  testWidgets(
      'tapping the row calls onTap with scheduledPaymentId, not the '
      "occurrence's synthetic id", (tester) async {
    String? tappedId;
    await pump(tester, onTap: (id) => tappedId = id);

    await tester.tap(find.byType(BudgetScheduledRow));
    await tester.pumpAndSettle();

    expect(tappedId, 'sp-1');
  });
}
