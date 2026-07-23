import 'package:billetudo/core/preferences/balance_carousel_cubit.dart';
import 'package:billetudo/core/preferences/balance_carousel_preference_datasource.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transactions_link_mode.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../categories/presentation/widgets/pump_widget.dart';

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
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.x));
    expect(cancelled, isTrue);
  });

  testWidgets('sin modo enlazar el FAB está presente', (tester) async {
    await pump(tester, linkMode: null);
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
  });
}
