import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/usecases/delete_account.dart';
import 'package:billetudo/features/auth/domain/usecases/wipe_local_data.dart';
import 'package:billetudo/features/auth/presentation/cubit/delete_account_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/delete_account_state.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/local_data_choice_row.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/local_data_choice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../pump_widget.dart';

class MockDeleteAccount extends Mock implements DeleteAccount {}

class MockWipeLocalData extends Mock implements WipeLocalData {}

void main() {
  late MockDeleteAccount deleteAccount;
  late MockWipeLocalData wipeLocalData;
  late DeleteAccountCubit cubit;

  setUp(() async {
    deleteAccount = MockDeleteAccount();
    wipeLocalData = MockWipeLocalData();
    when(() => deleteAccount()).thenAnswer((_) async => const Right(unit));
    cubit = DeleteAccountCubit(deleteAccount, wipeLocalData);
    // Drives the cubit to paso 2 through its real paso-1 transition, rather
    // than poking `emit` directly (protected outside the cubit).
    await cubit.confirmDelete();
    expect(cubit.state.step, DeleteAccountStep.localDataChoice);
  });

  testWidgets(
      'HU-07 paso 2 (no-dark-pattern): ninguna opción viene preseleccionada '
      'y el CTA arranca deshabilitado', (tester) async {
    await tester.pumpAuthWidget(
      BlocProvider.value(
        value: cubit,
        child: const LocalDataChoiceSheet(),
      ),
    );

    final rows = tester
        .widgetList<LocalDataChoiceRow>(find.byType(LocalDataChoiceRow))
        .toList();
    expect(rows, hasLength(2));
    expect(
      rows.every((row) => row.selected == false),
      isTrue,
      reason:
          'ninguna de las 2 filas debe llegar marcada — el usuario tiene que '
          'elegir explícitamente (HU-07)',
    );

    final cta = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(
      cta.onPressed,
      isNull,
      reason: 'el CTA "Continuar" debe estar deshabilitado sin elección',
    );
  });

  testWidgets('elegir "conservar" habilita el CTA y lo marca como elegida',
      (tester) async {
    await tester.pumpAuthWidget(
      BlocProvider.value(
        value: cubit,
        child: const LocalDataChoiceSheet(),
      ),
    );

    await tester.tap(find.text('Conservar mis datos en este dispositivo'));
    await tester.pump();

    final rows = tester
        .widgetList<LocalDataChoiceRow>(find.byType(LocalDataChoiceRow))
        .toList();
    expect(rows[0].selected, isTrue);
    expect(rows[1].selected, isFalse);

    final cta = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(cta.onPressed, isNotNull);
  });

  testWidgets(
      'elegir "borrar" y continuar llama a WipeLocalData y avanza a paso 3',
      (tester) async {
    when(() => wipeLocalData()).thenAnswer((_) async => const Right(unit));

    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => LocalDataChoiceSheet.show(context, cubit),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Borrar también los datos de este dispositivo'));
    await tester.pump();

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    verify(() => wipeLocalData()).called(1);
    expect(cubit.state.step, DeleteAccountStep.done);
    expect(find.byType(LocalDataChoiceSheet), findsNothing);
  });

  testWidgets('elegir "conservar" y continuar no toca WipeLocalData',
      (tester) async {
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => LocalDataChoiceSheet.show(context, cubit),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Conservar mis datos en este dispositivo'));
    await tester.pump();

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    verifyNever(() => wipeLocalData());
    expect(cubit.state.step, DeleteAccountStep.done);
  });
}
