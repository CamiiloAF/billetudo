import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/features/accounts/domain/usecases/has_any_active_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_active_accounts_count.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_bridge_sheet.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../categories/presentation/widgets/pump_widget.dart';

class MockTransactionsListCubit extends MockCubit<TransactionsListState>
    implements TransactionsListCubit {}

class MockHasAnyActiveAccount extends Mock implements HasAnyActiveAccount {}

class MockWatchActiveAccountsCount extends Mock
    implements WatchActiveAccountsCount {}

/// `15-gate-cuenta.md` HU-02/HU-04: tapping the FAB / new-transaction CTA in
/// Movimientos without any active account opens the bridge instead of
/// mounting a form that could never save.
void main() {
  void registerAccountGate({required bool hasAny}) {
    final hasAnyActiveAccount = MockHasAnyActiveAccount();
    when(hasAnyActiveAccount.call).thenAnswer((_) => Stream.value(hasAny));
    getIt.registerFactory<HasAnyActiveAccount>(() => hasAnyActiveAccount);
    final watchActiveAccountsCount = MockWatchActiveAccountsCount();
    when(watchActiveAccountsCount.call)
        .thenAnswer((_) => Stream.value(hasAny ? 1 : 0));
    getIt.registerFactory<WatchActiveAccountsCount>(
      () => watchActiveAccountsCount,
    );
  }

  tearDown(getIt.reset);

  Future<void> pumpAndTapFab(WidgetTester tester,
      {String? Function()? onAdd}) async {
    final listCubit = MockTransactionsListCubit();
    when(() => listCubit.state).thenReturn(
      TransactionsListState(
        status: TransactionsListStatus.ready,
        filter: TransactionFilter(),
      ),
    );
    await tester.pumpAppWidget(
      BlocProvider<TransactionsListCubit>.value(
        value: listCubit,
        child: TransactionsPage(
          onAddTransaction: (id) => onAdd?.call(),
          onOpenTransaction: (_) async => null,
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'sin ninguna cuenta activa, el FAB abre el puente en vez de invocar '
      'onAddTransaction', (tester) async {
    registerAccountGate(hasAny: false);
    var tapped = 0;
    await pumpAndTapFab(tester, onAdd: () {
      tapped++;
      return null;
    });

    expect(find.byType(AccountGateBridgeSheet), findsOneWidget);
    expect(tapped, 0);
  });

  testWidgets(
      'con al menos una cuenta activa, el FAB invoca onAddTransaction '
      'directamente, sin puente', (tester) async {
    registerAccountGate(hasAny: true);
    var tapped = 0;
    await pumpAndTapFab(tester, onAdd: () {
      tapped++;
      return null;
    });

    expect(find.byType(AccountGateBridgeSheet), findsNothing);
    expect(tapped, 1);
  });
}
