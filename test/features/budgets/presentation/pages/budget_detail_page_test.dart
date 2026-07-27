import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_view.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scheduled_item.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_detail_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_detail_state.dart';
import 'package:billetudo/features/budgets/presentation/pages/budget_detail_page.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_scheduled_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../golden/budget_golden_fixtures.dart';

class MockBudgetDetailCubit extends MockCubit<BudgetDetailState>
    implements BudgetDetailCubit {}

/// HU-12, criterion 8: the "programado" entry point on the detail hero.
void main() {
  late MockBudgetDetailCubit cubit;

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
  });

  setUp(() {
    cubit = MockBudgetDetailCubit();
  });

  Future<void> pump(WidgetTester tester, BudgetDetailState state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<BudgetDetailCubit>.value(
          value: cubit,
          child: BudgetDetailPage(
            onEdit: (_) {},
            onClosed: () {},
            onOpenTransaction: (_) async => null,
            onOpenScheduledPayment: (_) {},
            onSeeAllScheduled: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final scheduledItems = [
    BudgetScheduledItem(
      id: 'sp-1@2025-08-05T00:00:00.000',
      scheduledPaymentId: 'sp-1',
      note: 'Netflix',
      accountName: 'Bancolombia',
      amountMinor: 4500000,
      currency: 'COP',
      date: DateTime(2025, 8, 5),
    ),
  ];

  BudgetDetailState readyState({required int scheduledMinor}) {
    final entry = healthyEntry;
    return BudgetDetailState(
      status: BudgetDetailStatus.ready,
      budget: entry.budget,
      scope: entry.scope,
      view: BudgetPeriodView(
        window: entry.window,
        progress: BudgetProgress(
          amountMinor: entry.progress.amountMinor,
          spentMinor: entry.progress.spentMinor,
          daysLeft: entry.progress.daysLeft,
          scheduledMinor: scheduledMinor,
        ),
        activity: const [],
        scheduledItems: scheduledMinor > 0 ? scheduledItems : const [],
      ),
    );
  }

  testWidgets('with nothing programado, the entry row does not render',
      (tester) async {
    await pump(tester, readyState(scheduledMinor: 0));

    expect(find.textContaining('Programado'), findsNothing);
  });

  testWidgets(
      'with something programado, the entry row shows the figure and opens '
      'the sheet with what composes it', (tester) async {
    await pump(tester, readyState(scheduledMinor: 4500000));

    expect(find.text('Programado'), findsOneWidget);
    expect(find.textContaining(r'$45.000'), findsWidgets);

    await tester.tap(find.text('Programado'));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetScheduledSheet), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
  });
}
