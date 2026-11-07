import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transactions_link_mode.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../../transactions/transaction_fixtures.dart';

class MockTransactionsListCubit extends MockCubit<TransactionsListState>
    implements TransactionsListCubit {}

/// Movimientos in "modo enlazar" (`g0x859`/`Y71NB`, Deudas HU-02): the same
/// `TransactionsPage` list, but topped by the `$primary-soft` "Enlazar a …"
/// banner and with the FAB hidden — the `DebtLinkModePage` reuses this page
/// with a `TransactionsLinkMode` rather than copying the screen. Light + dark.
void main() {
  late MockTransactionsListCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockTransactionsListCubit());

  final items = [
    TransactionWithDetails(
      transaction: buildTransaction(
        id: 'tx-1',
        categoryId: 'cat-food',
        amountMinor: 68000000,
        date: DateTime(2026, 7, 15),
        note: 'Cuota crédito',
      ),
      accountName: 'Bancolombia',
      categoryName: 'Deudas',
      categoryIcon: 'landmark',
      categoryColor: 'indigo',
    ),
    TransactionWithDetails(
      transaction: buildTransaction(
        id: 'tx-2',
        categoryId: 'cat-shop',
        amountMinor: 4500000,
        date: DateTime(2026, 7, 14),
      ),
      accountName: 'Efectivo',
      categoryName: 'Compras',
      categoryIcon: 'shopping-bag',
      categoryColor: 'coral',
    ),
  ];

  final linkMode = TransactionsLinkMode(
    bannerTitle: 'Enlazar a Crédito vehicular',
    bannerBody:
        'Elige un movimiento que ya registraste; lo atribuimos a esta deuda, no creamos uno nuevo.',
    onCancel: () {},
    onLinkTransaction: (_) async {},
    requiredType: TransactionType.expense,
    notBefore: DateTime(2026),
  );

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(
      TransactionsListState(
        status: TransactionsListStatus.ready,
        items: items,
        accounts: const [],
        // Pinned to the golden clock so the default-month PeriodStepper label
        // is deterministic.
        filter: TransactionFilter(
          datePeriod: DatePeriodFilter.thisMonth(goldenReferenceNow),
        ),
      ),
    );
    await pumpWithFixedClock(
      tester,
      BlocProvider<TransactionsListCubit>.value(
        value: cubit,
        child: TransactionsPage(
          onAddTransaction: (_) {},
          onOpenTransaction: (_) async => null,
          linkMode: linkMode,
        ),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(TransactionsPage),
      matchesGoldenFile('goldens/debt_link_mode_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('banner de enlazar + lista ($suffix)', (tester) async {
      await golden(tester, 'banner_$suffix', brightness: brightness);
    });
  }
}
