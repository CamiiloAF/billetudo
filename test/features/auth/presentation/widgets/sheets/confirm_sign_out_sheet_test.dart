import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/repositories/sync_status_repository.dart';
import 'package:billetudo/core/sync/domain/usecases/get_pending_upload_count.dart';
import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/core/widgets/sheet_buttons_row.dart';
import 'package:billetudo/features/auth/domain/entities/local_data_choice.dart';
import 'package:billetudo/features/auth/presentation/cubit/sign_out_sheet_cubit.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/confirm_sign_out_sheet.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/delete_opt_in_row.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/unsynced_changes_warning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../pump_widget.dart';

class FakeSyncStatusRepository implements SyncStatusRepository {
  FakeSyncStatusRepository({this.count = 0});

  final int count;

  @override
  FutureResult<int> pendingUploadCount() async => Right(count);

  @override
  Stream<SyncState> watchSyncState() => const Stream<SyncState>.empty();
}

SignOutSheetCubit buildCubit({int pending = 0}) => SignOutSheetCubit(
      GetPendingUploadCount(FakeSyncStatusRepository(count: pending)),
    );

void main() {
  testWidgets(
      'HU-06: con el opt-in apagado explica que los datos locales quedan '
      'intactos, con tono neutral (no destructivo)', (tester) async {
    await tester.pumpAuthWidget(
      BlocProvider<SignOutSheetCubit>.value(
        value: buildCubit(),
        child: const ConfirmSignOutSheet(),
      ),
    );

    expect(find.text('Cerrar sesión'), findsWidgets);
    expect(
      find.textContaining('seguirán guardados en este teléfono'),
      findsOneWidget,
    );
    // Neutral log-out tone, not the `$expense`/warning tone used by the
    // genuinely destructive delete-account sheet.
    expect(find.byIcon(LucideIcons.logOut), findsWidgets);
    expect(find.byIcon(LucideIcons.triangleAlert), findsNothing);
  });

  testWidgets(
      'HU-06 (hallazgo crítico de auditoría): al marcar la casilla desaparece '
      'la promesa de que los datos "seguirán guardados"', (tester) async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await tester.pumpAuthWidget(
      BlocProvider<SignOutSheetCubit>.value(
        value: cubit,
        child: const ConfirmSignOutSheet(),
      ),
    );

    expect(
      find.textContaining('seguirán guardados en este teléfono'),
      findsOneWidget,
      reason: 'estado 1: conservar es el default y el mensaje lo dice',
    );

    await tester.tap(find.byType(DeleteOptInRow));
    await tester.pump();

    expect(
      find.textContaining('seguirán guardados'),
      findsNothing,
      reason: 'con el borrado activado esa promesa es literalmente falsa y '
          'quedaría a 30px de la fila que dice lo contrario',
    );
    expect(
      find.text(
        'Dejarás de sincronizar hasta que vuelvas a iniciar sesión.',
      ),
      findsOneWidget,
      reason: 'el mensaje se recorta, no desaparece entero',
    );
  });

  testWidgets(
      'marcar la casilla vuelve el CTA destructivo: `trash-2` y "Borrar y '
      'salir"', (tester) async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await tester.pumpAuthWidget(
      BlocProvider<SignOutSheetCubit>.value(
        value: cubit,
        child: const ConfirmSignOutSheet(),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(SheetButtonsRow),
        matching: find.byIcon(LucideIcons.logOut),
      ),
      findsOneWidget,
    );
    expect(find.text('Borrar y salir'), findsNothing);

    await tester.tap(find.byType(DeleteOptInRow));
    await tester.pump();

    expect(find.text('Borrar y salir'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SheetButtonsRow),
        matching: find.byIcon(LucideIcons.trash2),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SheetButtonsRow),
        matching: find.byIcon(LucideIcons.logOut),
      ),
      findsNothing,
    );
    // El header sigue neutral: la acción base es cerrar sesión, no borrar una
    // cuenta — nunca se vuelve el patrón `alert-triangle`.
    expect(find.byIcon(LucideIcons.triangleAlert), findsNothing);
    expect(
      find.descendant(
        of: find.byType(SheetMessage),
        matching: find.byIcon(LucideIcons.logOut),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'estado 3: con la casilla marcada y cambios en cola aparece el aviso '
      'con el conteo real', (tester) async {
    final cubit = buildCubit(pending: 3);
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpAuthWidget(
      BlocProvider<SignOutSheetCubit>.value(
        value: cubit,
        child: const ConfirmSignOutSheet(),
      ),
    );

    expect(
      find.byType(UnsyncedChangesWarning),
      findsNothing,
      reason: 'sin borrado no se pierde nada local, haya cola o no',
    );

    await tester.tap(find.byType(DeleteOptInRow));
    await tester.pump();

    expect(find.byType(UnsyncedChangesWarning), findsOneWidget);
    expect(find.textContaining('3 cambios siguen guardados'), findsOneWidget);
    // El aviso advierte, nunca bloquea: un sync atascado no puede dejar al
    // usuario sin poder borrar lo suyo (decisión #17).
    // `FilledButton.icon` construye una subclase privada, así que `byType` no
    // la encontraría: hay que buscar por predicado.
    final cta = tester.widget<FilledButton>(
      find.descendant(
        of: find.byType(SheetButtonsRow),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      ),
    );
    expect(cta.onPressed, isNotNull);
  });

  testWidgets('con la cola vacía (N=0) no se renderiza el bloque de aviso',
      (tester) async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpAuthWidget(
      BlocProvider<SignOutSheetCubit>.value(
        value: cubit,
        child: const ConfirmSignOutSheet(),
      ),
    );

    await tester.tap(find.byType(DeleteOptInRow));
    await tester.pump();

    expect(find.byType(UnsyncedChangesWarning), findsNothing);
    expect(find.textContaining('0 cambios'), findsNothing);
  });

  testWidgets('con 1 cambio en cola el aviso va en singular', (tester) async {
    final cubit = buildCubit(pending: 1);
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpAuthWidget(
      BlocProvider<SignOutSheetCubit>.value(
        value: cubit,
        child: const ConfirmSignOutSheet(),
      ),
    );

    await tester.tap(find.byType(DeleteOptInRow));
    await tester.pump();

    expect(find.textContaining('1 cambio sigue guardado'), findsOneWidget);
    expect(find.textContaining('ese cambio no quedará'), findsOneWidget);
  });

  testWidgets('cancelar resuelve `show` en null', (tester) async {
    LocalDataChoice? result;
    final cubit = buildCubit();
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await ConfirmSignOutSheet.show(context, cubit);
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('confirmar sin marcar la casilla resuelve en `keep`',
      (tester) async {
    LocalDataChoice? result;
    final cubit = buildCubit();
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await ConfirmSignOutSheet.show(context, cubit);
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final row = tester.widget<SheetButtonsRow>(find.byType(SheetButtonsRow));
    expect(row.right, isA<FilledButton>());

    // "Cerrar sesión" appears twice on screen (the sheet's title and its
    // CTA) — only the one inside `SheetButtonsRow` is the button.
    await tester.tap(
      find.descendant(
        of: find.byType(SheetButtonsRow),
        matching: find.text('Cerrar sesión'),
      ),
    );
    await tester.pumpAndSettle();

    expect(result, LocalDataChoice.keep);
  });

  testWidgets('marcar la casilla y confirmar resuelve en `delete`',
      (tester) async {
    LocalDataChoice? result;
    final cubit = buildCubit(pending: 2);
    addTearDown(cubit.close);
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await ConfirmSignOutSheet.show(context, cubit);
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DeleteOptInRow));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Borrar y salir'));
    await tester.pumpAndSettle();

    expect(result, LocalDataChoice.delete);
  });

  testWidgets(
      'cancelar después de marcar la casilla sigue resolviendo en null '
      '(la elección no se filtra por el camino de cancelar)', (tester) async {
    var called = false;
    LocalDataChoice? result;
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await ConfirmSignOutSheet.show(context, cubit);
            called = true;
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DeleteOptInRow));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(result, isNull);
  });
}
