import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/pending_occurrences_section.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_pending_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';

class MockPendingOccurrencesCubit extends MockCubit<PendingOccurrencesState>
    implements PendingOccurrencesCubit {}

void main() {
  late MockPendingOccurrencesCubit cubit;

  setUp(() {
    cubit = MockPendingOccurrencesCubit();
    when(() => cubit.undo()).thenAnswer((_) async {});
    when(() => cubit.dismissUndo()).thenAnswer((_) {});
  });

  Future<void> pumpSection(
    WidgetTester tester,
    PendingOccurrencesState state, {
    VoidCallback? onOpenPending,
  }) async {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream)
        .thenAnswer((_) => const Stream<PendingOccurrencesState>.empty());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<PendingOccurrencesCubit>.value(
          value: cubit,
          child: Scaffold(
            body: PendingOccurrencesSection(
              onOpenPending: onOpenPending ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders nothing when there are no pending occurrences',
      (tester) async {
    await pumpSection(
      tester,
      const PendingOccurrencesState(status: PendingOccurrencesStatus.ready),
    );

    expect(find.byType(ScheduledPendingCard), findsNothing);
  });

  testWidgets('renders the ScheduledPendingCard with every pending occurrence',
      (tester) async {
    final items = [
      buildPendingOccurrence(),
      buildPendingOccurrence(
        occurrence: buildOccurrence(id: 'occ-2'),
        scheduledPayment:
            buildScheduledPayment(id: 'sp-2', requiresConfirmation: true),
      )
    ];

    await pumpSection(
      tester,
      PendingOccurrencesState(
          status: PendingOccurrencesStatus.ready, items: items),
    );

    final card = tester.widget<ScheduledPendingCard>(
      find.byType(ScheduledPendingCard),
    );
    expect(card.items, items);
  });

  testWidgets('tapping "Revisar todas" calls onOpenPending', (tester) async {
    var opened = false;
    final items = [buildPendingOccurrence()];

    await pumpSection(
      tester,
      PendingOccurrencesState(
          status: PendingOccurrencesStatus.ready, items: items),
      onOpenPending: () => opened = true,
    );

    await tester.tap(find.text('Revisar todas'));
    await tester.pump();

    expect(opened, isTrue);
  });

  testWidgets(
      'a snooze undo shows the snoozed Snackbar, and tapping Deshacer calls cubit.undo()',
      (tester) async {
    final items = [buildPendingOccurrence()];
    final initial = PendingOccurrencesState(
        status: PendingOccurrencesStatus.ready, items: items);
    final withUndo = initial.copyWith(
      pendingUndo:
          const PendingOccurrenceUndo(occurrenceId: 'occ-1', isSnooze: true),
    );
    whenListen(cubit, Stream.value(withUndo), initialState: initial);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<PendingOccurrencesCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) =>
                  PendingOccurrencesSection(onOpenPending: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SnackBar), findsOneWidget);

    await tester.tap(find.text('Deshacer'));
    await tester.pump();

    verify(() => cubit.undo()).called(1);
  });
}
