import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/confirmation_sheet_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/confirmation_sheet_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/guided_review_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/guided_review_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/confirmation_sheet.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/scheduled_payment_view_details_link.dart';
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

/// The "Ver historial y detalles" entry point of the confirmation sheet: a
/// template with a pending occurrence is hidden from "Activos", so this link
/// is the only way to reach its detail page without confirming, skipping or
/// snoozing first.
///
/// Two contracts to pin down:
/// - the standalone sheet (pending lists) shows it and tapping it only
///   navigates: it pops with `cancelled` so the occurrence stays awaiting
///   (criterion 7, no one-tap shortcut);
/// - guided review (and the detail screen's own pending badge) do NOT show it,
///   because the batch flow must not be interrupted by a navigation.
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

  /// Opens `ConfirmationSheetBody` through a real `showModalBottomSheet` so the
  /// pop result is observable, and returns the future `onPressed` resolves to.
  Future<void> openStandalone(
    WidgetTester tester, {
    required VoidCallback? onViewDetails,
    required void Function(ConfirmationSheetResult?) onResult,
    ConfirmationSheetState? state,
  }) async {
    when(() => cubit.state)
        .thenReturn(state ?? ConfirmationSheetState.loaded(source));
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              onResult(
                await showModalBottomSheet<ConfirmationSheetResult>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) =>
                      BlocProvider<ConfirmationSheetCubit>.value(
                    value: cubit,
                    child: ConfirmationSheetBody(
                      onViewDetails: onViewDetails,
                    ),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
        brightness: Brightness.light,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'el sheet independiente muestra el link cuando el caller pasa '
      'onViewDetails', (tester) async {
    await openStandalone(
      tester,
      onViewDetails: () {},
      onResult: (_) {},
    );

    expect(find.byType(ScheduledPaymentViewDetailsLink), findsOneWidget);
    expect(find.text('Ver historial y detalles'), findsOneWidget);
  });

  testWidgets(
      'tocar el link cierra el sheet como cancelado (la ocurrencia sigue '
      'pendiente) y llama al callback de navegación', (tester) async {
    ConfirmationSheetResult? result;
    var navigations = 0;
    await openStandalone(
      tester,
      onViewDetails: () => navigations++,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Ver historial y detalles'));
    await tester.pumpAndSettle();

    // Criterion 7: the link only navigates, it never applies the occurrence.
    verifyNever(() => cubit.confirm());
    expect(result, ConfirmationSheetResult.cancelled);
    expect(navigations, 1);
  });

  testWidgets(
      'mientras guarda, el link queda inerte: no navega ni cierra el sheet',
      (tester) async {
    ConfirmationSheetResult? result;
    var navigations = 0;
    await openStandalone(
      tester,
      state: ConfirmationSheetState.loaded(source)
          .copyWith(status: ConfirmationSheetStatus.saving),
      onViewDetails: () => navigations++,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Ver historial y detalles'));
    await tester.pumpAndSettle();

    // The in-flight write owns the sheet: letting the link pop it would make
    // the settled `confirmed` listener pop whatever route sits on top then.
    expect(navigations, 0);
    expect(result, isNull);
    expect(find.text('Ver historial y detalles'), findsOneWidget);
  });

  testWidgets(
      'sin onViewDetails (badge pendiente de la pantalla de detalle) el link '
      'no se renderiza', (tester) async {
    await openStandalone(
      tester,
      onViewDetails: null,
      onResult: (_) {},
    );

    expect(find.byType(ScheduledPaymentViewDetailsLink), findsNothing);
    expect(find.text('Ver historial y detalles'), findsNothing);
  });

  testWidgets('la revisión guiada (Revisar todas) no muestra el link',
      (tester) async {
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

    expect(find.byType(ScheduledPaymentViewDetailsLink), findsNothing);
    expect(find.text('Ver historial y detalles'), findsNothing);
  });
}
