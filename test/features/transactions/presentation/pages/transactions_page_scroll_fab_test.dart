import 'package:billetudo/core/preferences/balance_carousel_cubit.dart';
import 'package:billetudo/core/preferences/balance_carousel_preference_datasource.dart';
import 'package:billetudo/core/widgets/scroll_aware_fab.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../categories/presentation/widgets/pump_widget.dart';
import '../../transaction_fixtures.dart';

class MockTransactionsListCubit extends MockCubit<TransactionsListState>
    implements TransactionsListCubit {}

class _FakeCarouselPrefs implements BalanceCarouselPreferenceDatasource {
  @override
  Future<bool> readCollapsed() async => false;

  @override
  Future<void> writeCollapsed({required bool collapsed}) async {}
}

/// GitHub issue #26: the movimientos FAB must hide/show on scroll, same as
/// `HomePage`'s own FAB — it used to render unconditionally regardless of
/// scroll direction.
void main() {
  List<TransactionWithDetails> buildManyItems() => [
        for (var i = 0; i < 40; i++)
          TransactionWithDetails(
            transaction: buildTransaction(
              id: 'tx-$i',
              amountMinor: 10000 + i,
              date: DateTime(2026, 7, 15).subtract(Duration(days: i)),
            ),
            accountName: 'Efectivo',
            categoryName: 'Comida',
            categoryIcon: 'utensils',
            categoryColor: 'coral',
          ),
      ];

  Future<void> pumpPage(WidgetTester tester) async {
    final cubit = MockTransactionsListCubit();
    when(() => cubit.state).thenReturn(
      TransactionsListState(
        status: TransactionsListStatus.ready,
        filter: TransactionFilter(),
        items: buildManyItems(),
      ),
    );
    final carousel = BalanceCarouselCubit(_FakeCarouselPrefs());

    await tester.pumpAppWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionsListCubit>.value(value: cubit),
          BlocProvider<BalanceCarouselCubit>.value(value: carousel),
        ],
        child: TransactionsPage(
          onAddTransaction: (_) {},
          onOpenTransaction: (_) async => null,
          onOpenAccount: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double fabOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(ScrollAwareFab),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .opacity;

  testWidgets('scrolling the list down hides the FAB', (tester) async {
    await pumpPage(tester);

    expect(fabOpacity(tester), 1);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(fabOpacity(tester), 0);
  });

  testWidgets('scrolling back up brings the FAB back', (tester) async {
    await pumpPage(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(fabOpacity(tester), 0);

    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(fabOpacity(tester), 1);
  });
}
