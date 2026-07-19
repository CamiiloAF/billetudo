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

class MockScheduledPaymentsListCubit
    extends MockCubit<ScheduledPaymentsListState>
    implements ScheduledPaymentsListCubit {}

class MockPendingOccurrencesCubit extends MockCubit<PendingOccurrencesState>
    implements PendingOccurrencesCubit {}

/// The "próximos vencimientos" list (HU-04).
///
/// Pencil rows: `with_data_with_pending` → `o0twiq` (lista con pendientes) ·
/// `with_data_no_pending` → `t6UXUo` (lista sin pendientes) · `empty` →
/// `YI1wY` (vacío total) · `no_active` → `U9jUDR` (0 activas + N terminadas) ·
/// `loading` → `QE1Wq` · `error` → `KeKke` · `finished_*` → el filtro
/// "Terminados" (`LmrIV`/`gD9g7`/`w3MUo`), que filtra esta misma lista en
/// sitio en vez de apilar una pantalla.
///
/// `ScheduledDueInChip`/
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

  // "Terminados": la fecha es fija a propósito (a diferencia de las activas,
  // que se comparan contra hoy): "Último pago" es una fecha histórica y no se
  // mueve con el calendario.
  final finishedItems = [
    ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(
        id: 'sp-fin-1',
        endDate: DateTime(2026, 3, 20),
        nextDate: DateTime(2026, 4, 20),
      ),
      accountName: 'Bancolombia',
      categoryName: 'Gimnasio',
      categoryIcon: 'dumbbell',
      categoryColor: 'sky',
      lastPaymentDate: DateTime(2026, 3, 15),
    ),
    ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(
        id: 'sp-fin-2',
        frequency: ScheduledPaymentFrequency.once,
        nextDate: DateTime(2025, 12, 20),
      ),
      accountName: 'Nequi',
      categoryName: 'Matrícula',
      categoryIcon: 'graduation-cap',
      categoryColor: 'indigo',
      lastPaymentDate: DateTime(2025, 12, 20),
    ),
  ];

  final pendingItems = [
    buildPendingOccurrence(
      occurrence: buildOccurrence(occurrenceDate: inDays(-1)),
      scheduledPayment:
          buildScheduledPayment(id: 'sp-2', requiresConfirmation: true),
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
        const ScheduledPaymentsListState(
            status: ScheduledPaymentsListStatus.ready),
        const PendingOccurrencesState(status: PendingOccurrencesStatus.ready),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error ($suffix)', (tester) async {
      await golden(
        tester,
        const ScheduledPaymentsListState(
            status: ScheduledPaymentsListStatus.failure),
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
          finishedItems: finishedItems,
        ),
        const PendingOccurrencesState(status: PendingOccurrencesStatus.ready),
        'with_data_no_pending_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('no active + terminadas ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentsListState(
          status: ScheduledPaymentsListStatus.ready,
          finishedStatus: ScheduledPaymentsListStatus.ready,
          finishedItems: finishedItems,
        ),
        const PendingOccurrencesState(status: PendingOccurrencesStatus.ready),
        'no_active_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('filtro Terminados, con datos ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentsListState(
          status: ScheduledPaymentsListStatus.ready,
          finishedStatus: ScheduledPaymentsListStatus.ready,
          filter: ScheduledPaymentsFilter.finished,
          items: items,
          finishedItems: finishedItems,
        ),
        const PendingOccurrencesState(status: PendingOccurrencesStatus.ready),
        'finished_with_data_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('filtro Terminados, carga ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentsListState(
          status: ScheduledPaymentsListStatus.ready,
          filter: ScheduledPaymentsFilter.finished,
          items: items,
          finishedItems: finishedItems,
        ),
        const PendingOccurrencesState(status: PendingOccurrencesStatus.ready),
        'finished_loading_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('filtro Terminados, error ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentsListState(
          status: ScheduledPaymentsListStatus.ready,
          finishedStatus: ScheduledPaymentsListStatus.failure,
          filter: ScheduledPaymentsFilter.finished,
          items: items,
          finishedItems: finishedItems,
        ),
        const PendingOccurrencesState(status: PendingOccurrencesStatus.ready),
        'finished_error_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data + pendientes acumulados ($suffix)', (tester) async {
      await golden(
        tester,
        ScheduledPaymentsListState(
          status: ScheduledPaymentsListStatus.ready,
          items: items,
          finishedItems: finishedItems,
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
