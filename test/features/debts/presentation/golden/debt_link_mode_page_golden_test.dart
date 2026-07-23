import 'package:billetudo/core/preferences/balance_carousel_cubit.dart';
import 'package:billetudo/core/preferences/balance_carousel_preference_datasource.dart';
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

/// In-memory prefs so the balance carousel renders expanded without touching
/// `shared_preferences`.
class _FakeCarouselPrefs implements BalanceCarouselPreferenceDatasource {
  @override
  Future<bool> readCollapsed() async => false;

  @override
  Future<void> writeCollapsed({required bool collapsed}) async {}
}

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
    debtLabel: 'Crédito vehicular · Yo debo',
    onCancel: () {},
    onLinkTransaction: (_) async {},
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
      ),
    );
    await pumpGolden(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionsListCubit>.value(value: cubit),
          BlocProvider<BalanceCarouselCubit>(
            create: (_) => BalanceCarouselCubit(_FakeCarouselPrefs()),
          ),
        ],
        child: TransactionsPage(
          onAddTransaction: (_) {},
          onOpenTransaction: (_) async => null,
          onOpenAccount: (_) {},
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
