import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/pending_occurrences_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../scheduled_payment_fixtures.dart';

class MockPendingOccurrencesCubit extends MockCubit<PendingOccurrencesState>
    implements PendingOccurrencesCubit {}

/// "Por confirmar" (HU-03/HU-04 overflow): every pending occurrence across
/// every manual-mode template.
///
/// Pencil row: `with_data` → `QkLV0` (subpantalla "Por confirmar",
/// desbordamiento). `empty`, `loading` and `error` are runtime states with
/// no frame of their own.
void main() {
  late MockPendingOccurrencesCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockPendingOccurrencesCubit());

  final items = [
    buildPendingOccurrence(
      scheduledPayment: buildScheduledPayment(requiresConfirmation: true),
      accountName: 'Bancolombia',
      categoryName: 'Suscripciones',
      categoryIcon: 'wifi',
      categoryColor: 'indigo',
    ),
    buildPendingOccurrence(
      occurrence: buildOccurrence(id: 'occ-2'),
      scheduledPayment: buildScheduledPayment(
        id: 'sp-2',
        type: ScheduledPaymentType.transfer,
        transferAccountId: 'acc-2',
        requiresConfirmation: true,
      ),
      accountName: 'Nequi',
      transferAccountName: 'Bancolombia',
    ),
  ];

  Future<void> golden(
    WidgetTester tester,
    PendingOccurrencesState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<PendingOccurrencesCubit>.value(
        value: cubit,
        child: const PendingOccurrencesPage(),
      ),
      brightness: brightness,
      settle: settle,
    );
    await expectLater(
      find.byType(PendingOccurrencesPage),
      matchesGoldenFile('goldens/pending_occurrences_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const PendingOccurrencesState(),
        'loading_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('failure ($suffix)', (tester) async {
      await golden(
        tester,
        const PendingOccurrencesState(status: PendingOccurrencesStatus.failure),
        'error_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('empty ($suffix)', (tester) async {
      await golden(
        tester,
        const PendingOccurrencesState(status: PendingOccurrencesStatus.ready),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data ($suffix)', (tester) async {
      await golden(
        tester,
        PendingOccurrencesState(
            status: PendingOccurrencesStatus.ready, items: items),
        'with_data_$suffix',
        brightness: brightness,
      );
    });
  }
}
