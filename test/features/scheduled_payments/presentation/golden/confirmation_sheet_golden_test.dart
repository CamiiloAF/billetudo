import 'package:billetudo/features/scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/confirmation_sheet_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/confirmation_sheet_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/guided_review_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/guided_review_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/confirmation_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../scheduled_payment_fixtures.dart';

class MockConfirmationSheetCubit extends MockCubit<ConfirmationSheetState>
    implements ConfirmationSheetCubit {}

class MockGuidedReviewCubit extends MockCubit<GuidedReviewState>
    implements GuidedReviewCubit {}

/// HU-03's mandatory confirmation sheet (criterion 7): a single pending
/// occurrence, the same sheet with 3+ accumulated occurrences of the same
/// template (the "Acumuladas" strip, criterion 11), and the guided-review
/// variant stepped through one at a time (`GuidedReviewSheet`, item 3).
///
/// Rendered by wiring `ConfirmationSheetBody`/`GuidedReviewSheetBody`
/// directly to a mocked, already-`ready` cubit instead of going through
/// `ConfirmationSheet.show`/`getIt`: the sheet's own `BlocProvider` resolves
/// its cubit from the DI container, which a golden test has no reason to
/// stand up (same pattern `snooze_sheet_golden_test.dart` follows).
void main() {
  late MockConfirmationSheetCubit cubit;
  late MockGuidedReviewCubit guidedCubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    cubit = MockConfirmationSheetCubit();
    guidedCubit = MockGuidedReviewCubit();
  });

  PendingScheduledOccurrence source({
    ScheduledPaymentType type = ScheduledPaymentType.expense,
  }) =>
      buildPendingOccurrence(
        scheduledPayment: buildScheduledPayment(
          type: type,
          transferAccountId: type == ScheduledPaymentType.transfer ? 'acc-2' : null,
          requiresConfirmation: true,
        ),
        accountName: 'Bancolombia',
        transferAccountName: type == ScheduledPaymentType.transfer ? 'Nequi' : null,
        categoryName: type == ScheduledPaymentType.transfer ? null : 'Suscripciones',
        categoryIcon: type == ScheduledPaymentType.transfer ? null : 'wifi',
        categoryColor: type == ScheduledPaymentType.transfer ? null : 'indigo',
      );

  // Opens the sheet through a real `showModalBottomSheet` (scrim, drag
  // handle and the `[28,28,0,0]` bottom sheet theme included, same as
  // `accounts/.../sheets_golden_test.dart`) instead of pumping the body
  // straight into a `Scaffold`: that chrome only exists once the widget is
  // actually shown as a modal route.
  Future<void> goldenStandalone(
    WidgetTester tester,
    ConfirmationSheetState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (context) => BlocProvider<ConfirmationSheetCubit>.value(
                value: cubit,
                child: const ConfirmationSheetBody(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_confirmation_$name.png'),
    );
  }

  Future<void> goldenGuided(
    WidgetTester tester,
    GuidedReviewState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => guidedCubit.state).thenReturn(state);
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (context) => BlocProvider<GuidedReviewCubit>.value(
                value: guidedCubit,
                child: const GuidedReviewSheetBody(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_confirmation_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('individual, gasto ($suffix)', (tester) async {
      await goldenStandalone(
        tester,
        ConfirmationSheetState.loaded(source()),
        'individual_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('transferencia: sin selector de cuenta destino ($suffix)',
        (tester) async {
      await goldenStandalone(
        tester,
        ConfirmationSheetState.loaded(source(type: ScheduledPaymentType.transfer)),
        'transfer_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('acumuladas ×3: muestra el strip ($suffix)', (tester) async {
      await goldenStandalone(
        tester,
        ConfirmationSheetState.loaded(source(), pendingCountForTemplate: 3),
        'accumulated_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('guardando: los botones se deshabilitan ($suffix)', (tester) async {
      await goldenStandalone(
        tester,
        ConfirmationSheetState.loaded(source())
            .copyWith(status: ConfirmationSheetStatus.saving),
        'saving_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('revisar todas (guiada): posición N de M, sin lápiz de editar ($suffix)',
        (tester) async {
      final queue = [source(), source(type: ScheduledPaymentType.income)];
      await goldenGuided(
        tester,
        GuidedReviewState(
          status: GuidedReviewStatus.ready,
          queue: queue,
          index: 0,
          date: queue.first.occurrence.effectiveDate,
          accountId: queue.first.scheduledPayment.accountId,
          accountName: queue.first.accountName,
          amountMinor: queue.first.scheduledPayment.amountMinor,
        ),
        'guided_$suffix',
        brightness: brightness,
      );
    });
  }
}
