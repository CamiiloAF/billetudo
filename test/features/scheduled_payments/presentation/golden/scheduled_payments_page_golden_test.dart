import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payments_list_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payments_list_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/scheduled_payments_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../scheduled_payment_fixtures.dart';

class MockScheduledPaymentsListCubit extends MockCubit<ScheduledPaymentsListState>
    implements ScheduledPaymentsListCubit {}

class MockPendingOccurrencesCubit extends MockCubit<PendingOccurrencesState>
    implements PendingOccurrencesCubit {}

/// The "próximos vencimientos" list (HU-04). `ScheduledDueInChip`/
/// `ScheduledPendingRow` compare their dates against `DateTime.now()` at
/// render time, so every fixture date here is built relative to "today"
/// (see [inDays]) instead of a hardcoded date — otherwise the "en N días"
/// text would drift a little every day this suite runs, which is not a real
/// regression.
void main() {
  late MockScheduledPaymentsListCubit listCubit;
  late MockPendingOccurrencesCubit pendingCubit;

  DateTime inDays(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    listCubit = MockScheduledPaymentsListCubit();
    pendingCubit = MockPendingOccurrencesCubit();
  });

  final items = [
    ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(nextDate: inDays(5)),
      accountName: 'Bancolombia',
      categoryName: 'Arriendo',
      categoryIcon: 'home',
      categoryColor: 'sky',
    ),
    ScheduledPaymentSummary(
      // `frequency: once` ("Pago único") combined with a two-digit "en N
      // días" pill used to overflow `ScheduledCard`'s second row by under a
      // pixel (RenderFlex overflow, `scheduled_card.dart:88`); fixed by
      // wrapping the frequency chip in `Flexible` + ellipsis. Kept as the
      // regression case instead of a shorter frequency label.
      scheduledPayment: buildScheduledPayment(
        id: 'sp-2',
        type: ScheduledPaymentType.income,
        frequency: ScheduledPaymentFrequency.once,
        nextDate: inDays(12),
      ),
      accountName: 'Nequi',
      categoryName: 'Salario',
      categoryIcon: 'banknote',
      categoryColor: 'mint',
      pendingOccurrenceCount: 3,
    ),
  ];

  final pendingItems = [
    buildPendingOccurrence(
      occurrence: buildOccurrence(occurrenceDate: inDays(-1)),
      scheduledPayment: buildScheduledPayment(id: 'sp-2', requiresConfirmation: true),
      accountName: 'Nequi',
      categoryName: 'Salario',
      categoryIcon: 'banknote',
      categoryColor: 'mint',
    ),
  ];

  Future<void> golden(
    WidgetTester tester,
    ScheduledPaymentsListState listState,
    PendingOccurrencesState pendingState,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => listCubit.state).thenReturn(listState);
    when(() => pendingCubit.state).thenReturn(pendingState);
    await pumpGolden(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<ScheduledPaymentsListCubit>.value(value: listCubit),
          BlocProvider<PendingOccurrencesCubit>.value(value: pendingCubit),
        ],
        child: ScheduledPaymentsPage(
          onAddScheduledPayment: () {},
          onOpenScheduledPayment: (_) {},
          onOpenPending: () {},
          onOpenFinished: () {},
        ),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1400),
      settle: settle,
    );
    await expectLater(
      find.byType(ScheduledPaymentsPage),
      matchesGoldenFile('goldens/scheduled_payments_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const ScheduledPaymentsListState(),
        const PendingOccurrencesState(),
        'loading_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('empty ($suffix)', (tester) async {
      await golden(
        tester,
        const ScheduledPaymentsListState(status: ScheduledPaymentsListStatus.ready),
        const PendingOccurrencesState(status: PendingOccurrencesStatus.ready),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error ($suffix)', (tester) async {
      await golden(
        tester,
        const ScheduledPaymentsListState(status: ScheduledPaymentsListStatus.failure),
        const PendingOccurrencesState(),
        'error_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data, no pending ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentsListState(
          status: ScheduledPaymentsListStatus.ready,
          items: items,
          finishedCount: 4,
        ),
        const PendingOccurrencesState(status: PendingOccurrencesStatus.ready),
        'with_data_no_pending_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data + pendientes acumulados ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentsListState(
          status: ScheduledPaymentsListStatus.ready,
          items: items,
          finishedCount: 4,
        ),
        PendingOccurrencesState(
          status: PendingOccurrencesStatus.ready,
          items: pendingItems,
        ),
        'with_data_with_pending_$suffix',
        brightness: brightness,
      );
    });
  }
}
