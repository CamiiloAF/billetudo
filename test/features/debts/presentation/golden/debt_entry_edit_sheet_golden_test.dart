import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_entry_edit_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_entry_edit_state.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_entry_edit_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/fake_note_suggestions.dart';
import '../../../../support/golden_helpers.dart';
import '../debts_presentation_fixtures.dart';

class MockDebtEntryEditCubit extends MockCubit<DebtEntryEditState>
    implements DebtEntryEditCubit {}

/// `DebtEntryEditSheet`'s two bodies — opened directly from `DebtLedgerRow`'s
/// tap (the merged sheet folds in what used to be the separate
/// `DebtMovementDetailSheet` step). `DebtFormat.relativeDate` reads
/// `clock.now()`, so every case pumps under `withClock` pinned to
/// [goldenReferenceNow] to keep the "hace X días" caption deterministic.
///
/// `DebtEntryEditSheetBody` (editable: abono/desembolso/ajuste) states
/// covered, each in light and dark:
///   - empty amount: submit CTA disabled.
///   - valid amount: submit CTA enabled.
///   - saving: submit CTA disabled mid-flight (same shape as empty amount,
///     but a distinct business state worth its own golden).
///   - a failure: the inline error message renders.
///
/// `DebtEntryReadOnlySheetBody` (interest accrual, never hand-edited) states
/// covered, each in light and dark:
///   - with a note: the Nota row renders below the divider.
///   - without a note: the divider and Nota row don't render at all.
void main() {
  late MockDebtEntryEditCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() {
    cubit = MockDebtEntryEditCubit();
    registerFakeNoteSuggestions();
  });
  tearDown(getIt.reset);

  final entry = DebtEntry(
    id: 'e1',
    debtId: 'd1',
    kind: DebtEntryKind.payment,
    amountMinor: -20000,
    note: 'Cuota de marzo',
    entryDate: DateTime(2026, 8, 5),
    createdAt: DateTime(2026, 8, 5),
    updatedAt: 0,
  );

  final debt =
      buildDebt(name: 'Crédito vehicular', direction: DebtDirection.iOwe);

  final interestEntry = DebtEntry(
    id: 'e2',
    debtId: 'd1',
    kind: DebtEntryKind.interestAccrual,
    amountMinor: 4500,
    note: 'Interés de agosto',
    entryDate: DateTime(2026, 8, 1),
    createdAt: DateTime(2026, 8, 1),
    updatedAt: 0,
  );

  DebtEntryEditState readOnlyStateWith({String note = 'Interés de agosto'}) =>
      DebtEntryEditState(
        entry: interestEntry,
        amountMinor: interestEntry.amountMinor,
        date: interestEntry.entryDate,
        note: note,
        runningMinor: 28350000,
      );

  DebtEntryEditState stateWith({
    int amountMinor = 20000,
    DebtEntryEditStatus status = DebtEntryEditStatus.ready,
    Failure? failure,
  }) =>
      DebtEntryEditState(
        entry: entry,
        amountMinor: amountMinor,
        date: entry.entryDate,
        note: entry.note ?? '',
        runningMinor: 28350000,
        status: status,
        failure: failure,
      );

  Future<void> goldenBody(
    WidgetTester tester,
    DebtEntryEditState state,
    String name, {
    required Brightness brightness,
    required Widget Function(DebtEntryEditState state) bodyBuilder,
  }) =>
      withClock(Clock.fixed(goldenReferenceNow), () async {
        when(() => cubit.state).thenReturn(state);
        setGoldenViewport(tester);
        await tester.pumpWidget(
          wrapForGolden(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => BottomSheetBase.show<void>(
                  context,
                  builder: (_) => BlocProvider<DebtEntryEditCubit>.value(
                    value: cubit,
                    child: bodyBuilder(state),
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
          matchesGoldenFile('goldens/debt_entry_edit_sheet_$name.png'),
        );
      });

  Future<void> golden(
    WidgetTester tester,
    DebtEntryEditState state,
    String name, {
    required Brightness brightness,
  }) =>
      goldenBody(
        tester,
        state,
        name,
        brightness: brightness,
        bodyBuilder: (state) => DebtEntryEditSheetBody(debt: debt, state: state),
      );

  Future<void> goldenReadOnly(
    WidgetTester tester,
    DebtEntryEditState state,
    String name, {
    required Brightness brightness,
  }) =>
      goldenBody(
        tester,
        state,
        name,
        brightness: brightness,
        bodyBuilder: (state) =>
            DebtEntryReadOnlySheetBody(debt: debt, state: state),
      );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('monto vacío: CTA deshabilitado ($suffix)', (tester) async {
      await golden(
        tester,
        stateWith(amountMinor: 0),
        'empty_amount_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('monto válido: CTA habilitado ($suffix)', (tester) async {
      await golden(
        tester,
        stateWith(amountMinor: 20000),
        'valid_amount_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('guardando: CTA deshabilitado ($suffix)', (tester) async {
      await golden(
        tester,
        stateWith(amountMinor: 20000, status: DebtEntryEditStatus.saving),
        'saving_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error: mensaje inline ($suffix)', (tester) async {
      await golden(
        tester,
        stateWith(
          amountMinor: 20000,
          failure: const ValidationFailure('boom'),
        ),
        'error_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('solo lectura: con nota ($suffix)', (tester) async {
      await goldenReadOnly(
        tester,
        readOnlyStateWith(),
        'readonly_with_note_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('solo lectura: sin nota ($suffix)', (tester) async {
      await goldenReadOnly(
        tester,
        readOnlyStateWith(note: ''),
        'readonly_no_note_$suffix',
        brightness: brightness,
      );
    });
  }
}
