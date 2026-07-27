import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/confirmation_sheet_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/confirmation_sheet_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/guided_review_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/guided_review_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_editable_amount_field.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/confirmation_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/golden_helpers.dart';
import '../../../scheduled_payment_fixtures.dart';

class MockConfirmationSheetCubit extends MockCubit<ConfirmationSheetState>
    implements ConfirmationSheetCubit {}

class MockGuidedReviewCubit extends MockCubit<GuidedReviewState>
    implements GuidedReviewCubit {}

/// Bug 6: `ConfirmationSheetFields.build()` used to stack the header, the
/// fields and the Posponer/Omitir + Confirmar footer in a single
/// `Column(mainAxisSize: min)` with no scroll boundary. Expanding the
/// editable amount field into its custom `NumericKeypad` (`AnimatedSize`, not
/// the system keyboard, so `MediaQuery.viewInsets.bottom` never reflects it)
/// then pushed the footer past the bottom of a regular phone-sized sheet,
/// overflowing instead of scrolling — in both `ConfirmationSheetBody` and
/// `GuidedReviewSheetBody`, which reuses the same fields widget.
void main() {
  late MockConfirmationSheetCubit cubit;
  late MockGuidedReviewCubit guidedCubit;

  setUp(() {
    cubit = MockConfirmationSheetCubit();
    guidedCubit = MockGuidedReviewCubit();
  });

  final source = buildPendingOccurrence(
    scheduledPayment: buildScheduledPayment(
      type: ScheduledPaymentType.expense,
      note: 'Netflix',
      amountMinor: 18000000,
      requiresConfirmation: true,
    ),
    accountName: 'Bancolombia',
    categoryName: 'Suscripciones',
    categoryIcon: 'wifi',
    categoryColor: 'indigo',
  );

  Future<void> expandKeypad(WidgetTester tester) => tester.tap(
        find.descendant(
          of: find.byType(ScheduledPaymentAmountCollapsed),
          matching: find.byType(IconButton),
        ),
      );

  testWidgets(
      'ConfirmationSheetBody: el keypad expandido no desborda un sheet de '
      'tamaño de teléfono normal', (tester) async {
    when(() => cubit.state).thenReturn(ConfirmationSheetState.loaded(source));
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
        brightness: Brightness.light,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expandKeypad(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'GuidedReviewSheetBody: el keypad expandido no desborda un sheet de '
      'tamaño de teléfono normal', (tester) async {
    final queue = [source];
    when(() => guidedCubit.state).thenReturn(
      GuidedReviewState(
        status: GuidedReviewStatus.ready,
        queue: queue,
        index: 0,
        date: queue.first.occurrence.effectiveDate,
        accountId: queue.first.scheduledPayment.accountId,
        accountName: queue.first.accountName,
        amountMinor: queue.first.scheduledPayment.amountMinor,
      ),
    );
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
        brightness: Brightness.light,
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expandKeypad(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
