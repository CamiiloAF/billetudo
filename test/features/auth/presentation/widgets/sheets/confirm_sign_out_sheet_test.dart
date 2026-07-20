import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/repositories/sync_status_repository.dart';
import 'package:billetudo/core/sync/domain/usecases/get_pending_upload_count.dart';
import 'package:billetudo/core/widgets/sheet_buttons_row.dart';
import 'package:billetudo/features/auth/domain/entities/local_data_choice.dart';
import 'package:billetudo/features/auth/presentation/cubit/sign_out_sheet_cubit.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/confirm_sign_out_sheet.dart';
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
}
