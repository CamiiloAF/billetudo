import 'package:billetudo/core/widgets/period_stepper.dart';
import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../categories/presentation/widgets/pump_widget.dart';

class MockTransactionsListCubit extends MockCubit<TransactionsListState>
    implements TransactionsListCubit {}

/// 2026-11-07: the `PeriodStepper` used to render only while the active Fecha
/// period was NOT the default "this month". Week and Year always differ from
/// that default the moment they are picked, so they showed it; Month — the
/// default itself — did not, and the user could not move between months
/// without reopening the filters sheet. It now renders for every granular
/// period, including the current month, while a custom range still has no
/// previous/next to step to.
void main() {
  late MockTransactionsListCubit listCubit;

  /// Pinned "today" so `datePeriodHasNext` (which reads `clock.now()`) and the
  /// period label are deterministic regardless of the host clock.
  final fixedNow = DateTime(2026, 8, 7, 12);

  setUp(() {
    listCubit = MockTransactionsListCubit();
    when(() => listCubit.stepPeriod(any())).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester,
    TransactionFilter filter,
  ) async {
    when(() => listCubit.state).thenReturn(
      TransactionsListState(
        status: TransactionsListStatus.ready,
        filter: filter,
      ),
    );
    await withClock(
      Clock.fixed(fixedNow),
      () => tester.pumpAppWidget(
        BlocProvider<TransactionsListCubit>.value(
          value: listCubit,
          child: TransactionsPage(
            onAddTransaction: (_) {},
            onOpenTransaction: (_) async => null,
          ),
        ),
      ),
    );
  }

  testWidgets(
      'el mes default ("este mes") sí muestra el PeriodStepper y '
      'solo deshabilita "siguiente"', (tester) async {
    await pump(
      tester,
      TransactionFilter(datePeriod: DatePeriodFilter.thisMonth(fixedNow)),
    );

    expect(find.byType(PeriodStepper), findsOneWidget);
    expect(find.text('Agosto 2026'), findsOneWidget);

    final stepper = tester.widget<PeriodStepper>(find.byType(PeriodStepper));
    expect(stepper.onPrevious, isNotNull);
    expect(stepper.onNext, isNull);
  });

  testWidgets('tocar "anterior" en el mes default navega al mes anterior',
      (tester) async {
    await pump(
      tester,
      TransactionFilter(datePeriod: DatePeriodFilter.thisMonth(fixedNow)),
    );

    final stepper = tester.widget<PeriodStepper>(find.byType(PeriodStepper));
    stepper.onPrevious!();
    await tester.pump();

    verify(() => listCubit.stepPeriod(-1)).called(1);
  });

  testWidgets('un mes pasado muestra ambas flechas habilitadas',
      (tester) async {
    await pump(
      tester,
      TransactionFilter(
        datePeriod: DatePeriodFilter.granular(
          DateGranularity.month,
          DateTime(2026, 5),
        ),
      ),
    );

    final stepper = tester.widget<PeriodStepper>(find.byType(PeriodStepper));
    expect(stepper.onPrevious, isNotNull);
    expect(stepper.onNext, isNotNull);
  });

  testWidgets('un rango personalizado NO muestra el PeriodStepper',
      (tester) async {
    await pump(
      tester,
      TransactionFilter(
        datePeriod: DatePeriodFilter.custom(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 5),
        ),
      ),
    );

    expect(find.byType(PeriodStepper), findsNothing);
  });
}
