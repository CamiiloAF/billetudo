import 'package:billetudo/features/capture/presentation/cubit/capture_review_item.dart';
import 'package:billetudo/features/capture/presentation/cubit/pending_captures_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/pending_captures_state.dart';
import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../../capture/capture_mocks.dart';

class MockTransactionsListCubit extends MockCubit<TransactionsListState>
    implements TransactionsListCubit {}

class MockPendingCapturesCubit extends MockCubit<PendingCapturesState>
    implements PendingCapturesCubit {}

Widget _withProviders(
  TransactionsListCubit listCubit,
  PendingCapturesCubit capturesCubit,
  Widget page,
) =>
    MultiBlocProvider(
      providers: [
        BlocProvider<TransactionsListCubit>.value(value: listCubit),
        BlocProvider<PendingCapturesCubit>.value(value: capturesCubit),
      ],
      child: page,
    );

/// Regression golden for the overflow fixed in `750e7224`: zero real
/// movements (`TransactionsEmptyState`) stacked with the pinned "Pendientes
/// de confirmar" block (`PendingCapturesListSlot`) above it — the "ghost row"
/// scenario `capture_inbox_patrol_test.dart` reproduced on device. A capture
/// never enters `TransactionsListState.items` (see `PendingCapturesListSlot`'s
/// own doc comment), so this state only shows up by combining an empty list
/// state with a non-empty `PendingCapturesState`, which no other golden here
/// does — every other `transactions_page_golden_test.dart` case leaves
/// `onDispatchCapture` null, which hides the slot outright.
void main() {
  late MockTransactionsListCubit listCubit;
  late MockPendingCapturesCubit capturesCubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    listCubit = MockTransactionsListCubit();
    capturesCubit = MockPendingCapturesCubit();
  });

  /// Pinned clock because the page renders the default current-month
  /// `PeriodStepper` label (2026-11-07) — see
  /// `transactions_page_golden_test.dart`'s own note.
  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => listCubit.state).thenReturn(
      TransactionsListState(
        status: TransactionsListStatus.ready,
        // Pinned to the golden clock, same reason as
        // `transactions_page_golden_test.dart`'s `golden` helper.
        filter: TransactionFilter(
          datePeriod: DatePeriodFilter.thisMonth(goldenReferenceNow),
        ),
      ),
    );
    when(() => capturesCubit.state).thenReturn(
      PendingCapturesState(
        items: [
          CaptureReviewItem(
            capture: buildPendingCapture(
              id: 'capture-1',
              merchantRaw: 'TIENDA D1 SANTA ROSA',
              amountMinor: 5847000,
              suggestedAccountId: 'acc-1',
            ),
            accountName: 'Cuenta Nu',
            issuerName: 'Nu',
            suggestedCategoryName: 'Mercado',
          ),
        ],
      ),
    );
    await pumpWithFixedClock(
      tester,
      _withProviders(
        listCubit,
        capturesCubit,
        TransactionsPage(
          onAddTransaction: (_) {},
          onOpenTransaction: (_) async => null,
          onDispatchCapture: (_) {},
        ),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(TransactionsPage),
      matchesGoldenFile(
        'goldens/transactions_page_empty_with_pending_captures_$name.png',
      ),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('empty movements with a pending capture ($suffix)',
        (tester) async {
      await golden(tester, suffix, brightness: brightness);
    });
  }
}
