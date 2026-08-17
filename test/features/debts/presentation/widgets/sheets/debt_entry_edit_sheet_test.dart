import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_entry.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_entry_edit_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_entry_edit_state.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_entry_edit_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/fake_note_suggestions.dart';
import '../../debts_presentation_fixtures.dart';

class MockDebtEntryEditCubit extends MockCubit<DebtEntryEditState>
    implements DebtEntryEditCubit {}

void main() {
  late MockDebtEntryEditCubit cubit;

  final editableEntry = DebtEntry(
    id: 'e1',
    debtId: 'd1',
    kind: DebtEntryKind.payment,
    amountMinor: -20000,
    note: 'Cuota de marzo',
    entryDate: DateTime(2026, 3, 1),
    createdAt: DateTime(2026, 3, 1),
    updatedAt: 0,
  );

  final interestEntry = DebtEntry(
    id: 'e2',
    debtId: 'd1',
    kind: DebtEntryKind.interestAccrual,
    amountMinor: 3600,
    note: 'Interés calculado automáticamente sobre el saldo pendiente.',
    entryDate: DateTime(2026, 3, 1),
    createdAt: DateTime(2026, 3, 1),
    updatedAt: 0,
  );

  DebtEntryEditState stateWith({
    DebtEntry? entry,
    int amountMinor = 20000,
    int runningMinor = 250000,
    DebtEntryEditStatus status = DebtEntryEditStatus.ready,
    Failure? failure,
  }) {
    final e = entry ?? editableEntry;
    return DebtEntryEditState(
      entry: e,
      amountMinor: amountMinor,
      date: e.entryDate,
      note: e.note ?? '',
      runningMinor: runningMinor,
      status: status,
      failure: failure,
    );
  }

  setUp(() {
    cubit = MockDebtEntryEditCubit();
    registerFakeNoteSuggestions();
  });

  tearDown(getIt.reset);

  Future<void> pumpEditable(
      WidgetTester tester, DebtEntryEditState state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<DebtEntryEditCubit>.value(
            value: cubit,
            child: DebtEntryEditSheetBody(
              debt: buildDebt(direction: DebtDirection.iOwe),
              state: state,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpReadOnly(
      WidgetTester tester, DebtEntryEditState state) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<DebtEntryEditCubit>.value(
            value: cubit,
            child: DebtEntryReadOnlySheetBody(
              debt: buildDebt(direction: DebtDirection.iOwe),
              state: state,
            ),
          ),
        ),
      ),
    );
  }

  group('editable body (abono/desembolso/ajuste)', () {
    testWidgets('with a positive amount, the submit CTA is enabled',
        (tester) async {
      await pumpEditable(tester, stateWith(amountMinor: 20000));

      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('debt-entry-edit-submit')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('with a zero amount, the submit CTA is disabled',
        (tester) async {
      await pumpEditable(tester, stateWith(amountMinor: 0));

      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('debt-entry-edit-submit')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('while saving, the submit CTA is disabled', (tester) async {
      await pumpEditable(
        tester,
        stateWith(amountMinor: 20000, status: DebtEntryEditStatus.saving),
      );

      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('debt-entry-edit-submit')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('tapping the CTA calls cubit.submit()', (tester) async {
      when(cubit.submit).thenAnswer((_) async {});
      await pumpEditable(tester, stateWith(amountMinor: 20000));

      await tester.tap(find.byKey(const ValueKey('debt-entry-edit-submit')));
      await tester.pump();

      verify(cubit.submit).called(1);
    });

    testWidgets('a failure renders the error message', (tester) async {
      await pumpEditable(
        tester,
        stateWith(
          amountMinor: 20000,
          failure: const ValidationFailure('boom'),
        ),
      );

      expect(
        find.text('No pudimos guardar los cambios. Intenta de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('with no failure, no error message renders', (tester) async {
      await pumpEditable(tester, stateWith(amountMinor: 20000));

      expect(
        find.text('No pudimos guardar los cambios. Intenta de nuevo.'),
        findsNothing,
      );
    });

    testWidgets('shows the read-only "Saldo después" row', (tester) async {
      await pumpEditable(tester, stateWith(runningMinor: 250000));

      expect(find.text('Saldo después'), findsOneWidget);
    });

    testWidgets(
        'tapping "Eliminar movimiento" confirms, then calls cubit.delete()',
        (tester) async {
      when(cubit.delete).thenAnswer((_) async {});
      await pumpEditable(tester, stateWith());

      await tester.tap(find.text('Eliminar movimiento'));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar este movimiento?'), findsOneWidget);

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      verify(cubit.delete).called(1);
    });

    testWidgets(
        'dismissing the confirm sheet without confirming never calls delete',
        (tester) async {
      await pumpEditable(tester, stateWith());

      await tester.tap(find.text('Eliminar movimiento'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(cubit.delete);
    });
  });

  group('read-only body (interest accrual)', () {
    testWidgets('renders the "Interés"/"Estimado" header, never Guardar',
        (tester) async {
      await pumpReadOnly(
        tester,
        stateWith(entry: interestEntry, amountMinor: 3600),
      );

      expect(find.text('Interés'), findsWidgets);
      expect(find.text('Estimado'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsNothing);
      expect(
          find.byKey(const ValueKey('debt-entry-edit-submit')), findsNothing);
    });

    testWidgets('shows fecha and nota as plain info rows', (tester) async {
      await pumpReadOnly(
        tester,
        stateWith(entry: interestEntry, amountMinor: 3600),
      );

      expect(find.text('Fecha'), findsOneWidget);
      expect(find.text('Nota'), findsOneWidget);
      expect(find.text(interestEntry.note!), findsOneWidget);
    });

    testWidgets('shows the "Saldo después" row', (tester) async {
      await pumpReadOnly(
        tester,
        stateWith(
            entry: interestEntry, amountMinor: 3600, runningMinor: 250000),
      );

      expect(find.text('Saldo después'), findsOneWidget);
    });

    testWidgets('tapping "Eliminar" confirms, then calls cubit.delete()',
        (tester) async {
      when(cubit.delete).thenAnswer((_) async {});
      await pumpReadOnly(
        tester,
        stateWith(entry: interestEntry, amountMinor: 3600),
      );

      await tester.tap(find.byKey(const ValueKey('debt-entry-edit-delete')));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar este movimiento?'), findsOneWidget);

      // The confirm sheet's own "Eliminar" stacks on top of the read-only
      // body's identically-labeled delete button, still mounted underneath.
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      verify(cubit.delete).called(1);
    });
  });
}
