import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/app_fab.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payments_list_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payments_list_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/scheduled_payments_page.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_card.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_filter_chips.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_filter_chips_placeholder.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_finished_chip.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_finished_filter_view.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_skeleton_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';

class MockScheduledPaymentsListCubit
    extends MockCubit<ScheduledPaymentsListState>
    implements ScheduledPaymentsListCubit {}

class MockPendingOccurrencesCubit extends MockCubit<PendingOccurrencesState>
    implements PendingOccurrencesCubit {}

void main() {
  late MockScheduledPaymentsListCubit listCubit;
  late MockPendingOccurrencesCubit pendingCubit;

  final finishedSummary = ScheduledPaymentSummary(
    scheduledPayment: buildScheduledPayment(id: 'sp-finished'),
    accountName: 'Bancolombia',
    categoryName: 'Gimnasio',
    lastPaymentDate: DateTime(2026, 3, 15),
  );

  setUp(() {
    listCubit = MockScheduledPaymentsListCubit();
    pendingCubit = MockPendingOccurrencesCubit();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    ScheduledPaymentsListState listState, {
    PendingOccurrencesState pendingState = const PendingOccurrencesState(
      status: PendingOccurrencesStatus.ready,
    ),
    ValueChanged<String>? onOpenScheduledPayment,
  }) async {
    when(() => listCubit.state).thenReturn(listState);
    when(() => listCubit.stream)
        .thenAnswer((_) => const Stream<ScheduledPaymentsListState>.empty());
    when(() => pendingCubit.state).thenReturn(pendingState);
    when(() => pendingCubit.stream)
        .thenAnswer((_) => const Stream<PendingOccurrencesState>.empty());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ScheduledPaymentsListCubit>.value(value: listCubit),
            BlocProvider<PendingOccurrencesCubit>.value(value: pendingCubit),
          ],
          child: ScheduledPaymentsPage(
            onAddScheduledPayment: () {},
            onOpenScheduledPayment: onOpenScheduledPayment ?? (_) {},
            onOpenPending: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('loading: renders 5 skeleton cards, not a spinner',
      (tester) async {
    await pumpPage(
      tester,
      const ScheduledPaymentsListState(),
    );

    expect(find.byType(ScheduledSkeletonCard), findsNWidgets(5));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
      'a template with a pending occurrence is not repeated as a card, but '
      'still counts as active', (tester) async {
    final items = [
      ScheduledPaymentSummary(
        scheduledPayment: buildScheduledPayment(),
        accountName: 'Bancolombia',
        categoryName: 'Arriendo',
        pendingOccurrenceCount: 2,
      ),
      ScheduledPaymentSummary(
        scheduledPayment: buildScheduledPayment(id: 'sp-2'),
        accountName: 'Nequi',
        categoryName: 'Salario',
      ),
    ];

    await pumpPage(
      tester,
      ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        items: items,
      ),
    );

    expect(find.byType(ScheduledCard), findsOneWidget);
    expect(find.text('Activos · 2'), findsOneWidget);
  });

  testWidgets('empty: short copy and the "Programar un pago" CTA',
      (tester) async {
    await pumpPage(
      tester,
      const ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
      ),
    );

    expect(find.text('Aún no tienes pagos programados'), findsOneWidget);
    expect(find.text('Programar un pago'), findsOneWidget);
    // Vacío total: sin plantillas de ninguna clase no hay nada que filtrar.
    expect(find.byType(ScheduledFilterChips), findsNothing);
  });

  testWidgets('con 0 activas y N terminadas el vacío conserva los chips',
      (tester) async {
    await pumpPage(
      tester,
      ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        finishedStatus: ScheduledPaymentsListStatus.ready,
        finishedItems: [finishedSummary],
      ),
    );

    expect(find.byType(ScheduledFilterChips), findsOneWidget);
    expect(find.text('Terminados · 1'), findsOneWidget);
  });

  testWidgets('el chip de Terminados no existe cuando el contador es 0',
      (tester) async {
    await pumpPage(
      tester,
      ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        finishedStatus: ScheduledPaymentsListStatus.ready,
        items: [
          ScheduledPaymentSummary(
            scheduledPayment: buildScheduledPayment(),
            accountName: 'Bancolombia',
          ),
        ],
      ),
    );

    expect(find.text('Activos · 1'), findsOneWidget);
    expect(find.textContaining('Terminados'), findsNothing);
  });

  testWidgets('tocar el chip de Terminados filtra en sitio, no navega',
      (tester) async {
    await pumpPage(
      tester,
      ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        finishedStatus: ScheduledPaymentsListStatus.ready,
        items: [
          ScheduledPaymentSummary(
            scheduledPayment: buildScheduledPayment(),
            accountName: 'Bancolombia',
          ),
        ],
        finishedItems: [finishedSummary],
      ),
    );

    await tester.tap(find.text('Terminados · 1'));
    await tester.pump();

    verify(() => listCubit.showFilter(ScheduledPaymentsFilter.finished))
        .called(1);
  });

  testWidgets(
      'dentro del filtro: tarjetas terminadas, chips visibles y la frase que '
      'aclara que los movimientos siguen ahí', (tester) async {
    await pumpPage(
      tester,
      ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        finishedStatus: ScheduledPaymentsListStatus.ready,
        filter: ScheduledPaymentsFilter.finished,
        finishedItems: [finishedSummary],
      ),
    );

    expect(find.byType(ScheduledFilterChips), findsOneWidget);
    expect(find.byType(ScheduledCard), findsOneWidget);
    expect(find.byType(ScheduledFinishedChip), findsOneWidget);
    expect(find.byType(ScheduledFrequencyChip), findsNothing);
    expect(find.text('Último pago · 15 mar 2026'), findsOneWidget);
    expect(find.byType(ScheduledFinishedCaption), findsOneWidget);
  });

  testWidgets('el error del filtro conserva los chips y omite la frase',
      (tester) async {
    await pumpPage(
      tester,
      ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        finishedStatus: ScheduledPaymentsListStatus.failure,
        filter: ScheduledPaymentsFilter.finished,
        finishedItems: [finishedSummary],
      ),
    );

    expect(find.byType(ScheduledFilterChips), findsOneWidget);
    expect(find.byType(ScheduledFinishedCaption), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets(
      'la carga del filtro muestra min(N, 5) skeletons con los chips visibles',
      (tester) async {
    await pumpPage(
      tester,
      ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        filter: ScheduledPaymentsFilter.finished,
        finishedItems: [finishedSummary],
      ),
    );

    expect(find.byType(ScheduledFilterChips), findsOneWidget);
    expect(find.byType(ScheduledFinishedCaption), findsOneWidget);
    // El chip dice "Terminados · 1": cinco skeletons lo contradirían y la
    // lista encogería al resolver.
    expect(find.byType(ScheduledSkeletonCard), findsOneWidget);
    expect(find.byType(ScheduledFilterChipsPlaceholder), findsNothing);
  });

  testWidgets(
      'la carga del filtro se topa en 5 skeletons aunque haya más terminadas',
      (tester) async {
    await pumpPage(
      tester,
      ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        filter: ScheduledPaymentsFilter.finished,
        finishedItems: List<ScheduledPaymentSummary>.filled(8, finishedSummary),
      ),
    );

    expect(find.byType(ScheduledSkeletonCard), findsNWidgets(5));
  });

  testWidgets(
      'la carga inicial reserva el alto de la fila de chips con un '
      'placeholder, sin pintar los chips reales', (tester) async {
    await pumpPage(
      tester,
      const ScheduledPaymentsListState(),
    );

    expect(find.byType(ScheduledFilterChips), findsNothing);
    expect(find.byType(ScheduledFilterChipsPlaceholder), findsOneWidget);
    expect(find.byType(ScheduledSkeletonCard), findsNWidgets(5));
  });

  testWidgets('el error inicial no lleva placeholder de chips: es terminal',
      (tester) async {
    await pumpPage(
      tester,
      const ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.failure,
      ),
    );

    expect(find.byType(ScheduledFilterChipsPlaceholder), findsNothing);
    expect(find.byType(ScheduledFilterChips), findsNothing);
  });

  testWidgets(
      '0 activas + N terminadas: título "Por ahora" y subtítulo que apunta al '
      'chip «Terminados» por su nombre literal', (tester) async {
    await pumpPage(
      tester,
      ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        finishedStatus: ScheduledPaymentsListStatus.ready,
        finishedItems: [finishedSummary, finishedSummary, finishedSummary],
      ),
    );

    expect(
      find.text('Por ahora no tienes pagos programados activos'),
      findsOneWidget,
    );
    expect(
      find.text('Tus 3 pagos terminados siguen disponibles en «Terminados».'),
      findsOneWidget,
    );
    // El copy de primer uso es de `YI1wY`, no de aquí: este usuario sí tuvo
    // pagos programados.
    expect(find.text('Aún no tienes pagos programados'), findsNothing);
  });

  testWidgets('con una sola terminada el subtítulo va en singular',
      (tester) async {
    await pumpPage(
      tester,
      ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        finishedStatus: ScheduledPaymentsListStatus.ready,
        finishedItems: [finishedSummary],
      ),
    );

    expect(
      find.text('Tu pago terminado sigue disponible en «Terminados».'),
      findsOneWidget,
    );
  });

  testWidgets('el vacío total conserva el copy de primer uso', (tester) async {
    await pumpPage(
      tester,
      const ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        finishedStatus: ScheduledPaymentsListStatus.ready,
      ),
    );

    expect(find.text('Aún no tienes pagos programados'), findsOneWidget);
    expect(find.byType(ScheduledFilterChips), findsNothing);
  });

  testWidgets(
      'con la lista al final, la última tarjeta queda por encima del FAB',
      (tester) async {
    await pumpPage(
      tester,
      ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        items: [
          for (var i = 0; i < 8; i++)
            ScheduledPaymentSummary(
              scheduledPayment: buildScheduledPayment(id: 'sp-$i'),
              accountName: 'Bancolombia',
              categoryName: 'Categoría $i',
            ),
        ],
      ),
    );

    // Dragged repeatedly on purpose: the list is lazy, so each drag builds
    // more cards and grows the scroll extent, and a single drag stops short of
    // the real end no matter how long it is.
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -4000));
      await tester.pumpAndSettle();
    }

    // `Content.padding` bottom = 92 en `o0twiq`: es el colchón del FAB, no
    // decoración. Con menos, la última tarjeta queda tapada al final del
    // scroll.
    final lastCard = tester.getRect(find.byType(ScheduledCard).last);
    final fab = tester.getRect(find.byType(AppFab));
    expect(lastCard.bottom, lessThanOrEqualTo(fab.top));
  });

  testWidgets('tocar una tarjeta terminada abre su detalle', (tester) async {
    String? opened;
    await pumpPage(
      tester,
      ScheduledPaymentsListState(
        status: ScheduledPaymentsListStatus.ready,
        finishedStatus: ScheduledPaymentsListStatus.ready,
        filter: ScheduledPaymentsFilter.finished,
        finishedItems: [finishedSummary],
      ),
      onOpenScheduledPayment: (id) => opened = id,
    );

    await tester.tap(find.byType(ScheduledCard));
    await tester.pump();

    expect(opened, 'sp-finished');
  });
}
