import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/finished_scheduled_payments_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/finished_scheduled_payments_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/finished_scheduled_payments_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../scheduled_payment_fixtures.dart';

class MockFinishedScheduledPaymentsCubit
    extends MockCubit<FinishedScheduledPaymentsState>
    implements FinishedScheduledPaymentsCubit {}

/// The "Terminados" history (HU-04 overflow): templates that no longer
/// generate occurrences.
void main() {
  late MockFinishedScheduledPaymentsCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockFinishedScheduledPaymentsCubit());

  final items = [
    ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(
        endDate: DateTime(2026, 1, 1),
        nextDate: DateTime(2026, 6, 1),
      ),
      accountName: 'Bancolombia',
      categoryName: 'Arriendo',
      categoryIcon: 'home',
      categoryColor: 'sky',
    ),
    ScheduledPaymentSummary(
      scheduledPayment: buildScheduledPayment(id: 'sp-2', tombstonedAt: DateTime(2026, 5, 1)),
      accountName: 'Nequi',
      categoryName: 'Internet',
      categoryIcon: 'wifi',
      categoryColor: 'indigo',
    ),
  ];

  Future<void> golden(
    WidgetTester tester,
    FinishedScheduledPaymentsState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<FinishedScheduledPaymentsCubit>.value(
        value: cubit,
        child: FinishedScheduledPaymentsPage(onOpenScheduledPayment: (_) {}),
      ),
      brightness: brightness,
      settle: settle,
    );
    await expectLater(
      find.byType(FinishedScheduledPaymentsPage),
      matchesGoldenFile('goldens/finished_scheduled_payments_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const FinishedScheduledPaymentsState(),
        'loading_$suffix',
        brightness: brightness,
        settle: false,
      );
    });

    testWidgets('error ($suffix)', (tester) async {
      await golden(
        tester,
        const FinishedScheduledPaymentsState(
          status: FinishedScheduledPaymentsStatus.failure,
          failure: DatabaseFailure('boom'),
        ),
        'error_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('empty ($suffix)', (tester) async {
      await golden(
        tester,
        const FinishedScheduledPaymentsState(
          status: FinishedScheduledPaymentsStatus.ready,
        ),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data ($suffix)', (tester) async {
      await golden(
        tester,
        FinishedScheduledPaymentsState(
          status: FinishedScheduledPaymentsStatus.ready,
          items: items,
        ),
        'with_data_$suffix',
        brightness: brightness,
      );
    });
  }
}
