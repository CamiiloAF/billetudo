import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/widgets/sheet_buttons_row.dart';
import 'package:billetudo/features/auth/domain/usecases/delete_account.dart';
import 'package:billetudo/features/auth/domain/usecases/wipe_local_data.dart';
import 'package:billetudo/features/auth/presentation/cubit/delete_account_cubit.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/confirm_delete_account_sheet.dart';
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

  setUp(() {
    deleteAccount = MockDeleteAccount();
    wipeLocalData = MockWipeLocalData();
    cubit = DeleteAccountCubit(deleteAccount, wipeLocalData);
  });

  testWidgets(
      'HU-07 paso 1: tono destructivo explícito, irreversibilidad en el '
      'mensaje', (tester) async {
    await tester.pumpAuthWidget(
      BlocProvider.value(
        value: cubit,
        child: const ConfirmDeleteAccountSheet(),
      ),
    );

    expect(find.text('Eliminar tu cuenta'), findsOneWidget);
    expect(find.textContaining('no se puede deshacer'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    final row = tester.widget<SheetButtonsRow>(find.byType(SheetButtonsRow));
    expect(row.left, isA<OutlinedButton>());
    // The destructive CTA is the primary action here, unlike Cerrar Sesión's
    // neutral tone — it's `FilledButton` styled with `$expense`.
    expect(row.right, isA<FilledButton>());
  });

  testWidgets(
      'confirmar llama a DeleteAccount y la hoja se cierra al avanzar a '
      'paso 2', (tester) async {
    when(() => deleteAccount()).thenAnswer((_) async => const Right(unit));

    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => ConfirmDeleteAccountSheet.show(context, cubit),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar cuenta'));
    await tester.pumpAndSettle();

    verify(() => deleteAccount()).called(1);
    expect(find.byType(ConfirmDeleteAccountSheet), findsNothing);
  });

  testWidgets(
      'un fallo cambia al variante de error neutral con "Reintentar", sin '
      'cerrar la hoja', (tester) async {
    when(() => deleteAccount())
        .thenAnswer((_) async => const Left(NetworkFailure('offline')));

    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => ConfirmDeleteAccountSheet.show(context, cubit),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar cuenta'));
    await tester.pumpAndSettle();

    // Still open: paso 1's error does not advance the flow.
    expect(find.byType(ConfirmDeleteAccountSheet), findsOneWidget);
    expect(find.text('No pudimos eliminar tu cuenta'), findsOneWidget);
    // Neutral icon, not the destructive one — this is a technical failure,
    // not the irreversibility warning anymore.
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
