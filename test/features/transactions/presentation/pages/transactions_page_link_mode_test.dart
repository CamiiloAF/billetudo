import 'package:billetudo/core/preferences/balance_carousel_cubit.dart';
import 'package:billetudo/core/preferences/balance_carousel_preference_datasource.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_row.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transactions_link_mode.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

void main() {
  late MockTransactionsListCubit listCubit;

  setUp(() => listCubit = MockTransactionsListCubit());

  Future<void> pump(
    WidgetTester tester, {
    required TransactionsLinkMode? linkMode,
  }) async {
    when(() => listCubit.state).thenReturn(
      TransactionsListState(
        status: TransactionsListStatus.ready,
        filter: TransactionFilter(),
      ),
    );
    final carousel = BalanceCarouselCubit(_FakeCarouselPrefs());
    await tester.pumpAppWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionsListCubit>.value(value: listCubit),
          BlocProvider<BalanceCarouselCubit>.value(value: carousel),
        ],
        child: TransactionsPage(
          onAddTransaction: (_) {},
          onOpenTransaction: (_) async => null,
          onOpenAccount: (_) {},
          linkMode: linkMode,
        ),
      ),
    );
  }

  testWidgets('modo enlazar muestra el banner y oculta el FAB',
      (tester) async {
    await pump(
      tester,
      linkMode: TransactionsLinkMode(
        debtLabel: 'Crédito vehicular · Yo debo',
        onCancel: () {},
        onLinkTransaction: (_) async {},
        requiredType: TransactionType.expense,
        notBefore: DateTime(2000),
      ),
    );

    expect(
      find.text('Enlazar a Crédito vehicular · Yo debo'),
      findsOneWidget,
    );
    expect(find.byIcon(LucideIcons.plus), findsNothing);
  });

  testWidgets('la "x" del banner cancela el modo enlazar', (tester) async {
    var cancelled = false;
    await pump(
      tester,
      linkMode: TransactionsLinkMode(
        debtLabel: 'Crédito vehicular · Yo debo',
        onCancel: () => cancelled = true,
        onLinkTransaction: (_) async {},
        requiredType: TransactionType.expense,
        notBefore: DateTime(2000),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.x));
    expect(cancelled, isTrue);
  });

  testWidgets('sin modo enlazar el FAB está presente', (tester) async {
    await pump(tester, linkMode: null);
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
  });

  group('modo enlazar filtra por tipo y fecha (3a/3b)', () {
    final debtCreatedAt = DateTime(2026, 3, 10);

    TransactionWithDetails item({
      required String id,
      required TransactionType type,
      required DateTime date,
    }) =>
        TransactionWithDetails(
          transaction: buildTransaction(id: id, type: type, date: date),
          accountName: 'Bancolombia',
        );

    Future<void> pumpWithItems(
      WidgetTester tester, {
      required List<TransactionWithDetails> items,
      required TransactionType requiredType,
    }) async {
      when(() => listCubit.state).thenReturn(
        TransactionsListState(
          status: TransactionsListStatus.ready,
          filter: TransactionFilter(),
          items: items,
        ),
      );
      final carousel = BalanceCarouselCubit(_FakeCarouselPrefs());
      await tester.pumpAppWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<TransactionsListCubit>.value(value: listCubit),
            BlocProvider<BalanceCarouselCubit>.value(value: carousel),
          ],
          child: TransactionsPage(
            onAddTransaction: (_) {},
            onOpenTransaction: (_) async => null,
            onOpenAccount: (_) {},
            linkMode: TransactionsLinkMode(
              debtLabel: 'Crédito · Yo debo',
              onCancel: () {},
              onLinkTransaction: (_) async {},
              requiredType: requiredType,
              notBefore: debtCreatedAt,
            ),
          ),
        ),
      );
    }

    testWidgets('Yo debo: solo gastos en o después de la creación', (
      tester,
    ) async {
      await pumpWithItems(
        tester,
        requiredType: TransactionType.expense,
        items: [
          // Visible: gasto posterior a la creación.
          item(
            id: 'ok',
            type: TransactionType.expense,
            date: DateTime(2026, 4, 1),
          ),
          // Oculto: es un ingreso (tipo equivocado).
          item(
            id: 'wrong-type',
            type: TransactionType.income,
            date: DateTime(2026, 4, 1),
          ),
          // Oculto: gasto pero anterior a la creación de la deuda.
          item(
            id: 'too-old',
            type: TransactionType.expense,
            date: DateTime(2026, 3, 9),
          ),
        ],
      );

      expect(find.byType(TransactionRow), findsOneWidget);
    });

    testWidgets('un gasto del mismo día que la creación sí es enlazable', (
      tester,
    ) async {
      await pumpWithItems(
        tester,
        requiredType: TransactionType.expense,
        items: [
          item(
            id: 'same-day',
            type: TransactionType.expense,
            date: DateTime(2026, 3, 10, 23, 59),
          ),
        ],
      );

      expect(find.byType(TransactionRow), findsOneWidget);
    });
  });
}
