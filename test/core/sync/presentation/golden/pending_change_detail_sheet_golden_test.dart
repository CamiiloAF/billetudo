import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_cubit.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_state.dart';
import 'package:billetudo/core/sync/presentation/models/pending_sync_change.dart';
import 'package:billetudo/core/sync/presentation/widgets/sheets/pending_change_detail_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

class MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// "Detalle de la operación" (`r1qQYc`/`YzMN5`), abierta desde una fila.
///
/// Tres casos de negocio distinguibles: un cambio que trae monto y fecha en su
/// payload (un movimiento), uno que no trae ninguno de los dos — el subtítulo
/// desaparece entero en vez de inventar un relleno — y uno cuyo payload no
/// trae con qué nombrarlo, donde el título se queda solo con el tipo de
/// entidad.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  final now = goldenReferenceNow;

  PendingSyncChange change({required bool withAmount}) =>
      PendingSyncChange.fromOperation(
        QuarantinedOperation(
          id: 'q-1',
          operation: SyncOperation(
            tableName: withAmount ? 'transactions' : 'accounts',
            rowId: 'row-1',
            type: SyncOperationType.put,
            payload: withAmount
                ? {
                    'note': 'Café con Ana',
                    'amount_minor': 1800000,
                    'currency': 'COP',
                    'date': DateTime.utc(2026, 7, 12).millisecondsSinceEpoch ~/
                        1000,
                  }
                : const {'name': 'Cuenta de ahorros'},
          ),
          kind: SyncFailureKind.brokenSchema,
          errorCode: 'PGRST204',
          errorMessage: 'column does not exist',
          quarantinedAt: now.subtract(const Duration(days: 3)),
          updatedAt: now,
          attempts: 8,
        ),
      );

  Future<void> golden(
    WidgetTester tester,
    PendingSyncChange value,
    String name, {
    required Brightness brightness,
  }) async {
    final cubit = MockSyncStatusCubit();
    whenListen(
      cubit,
      const Stream<SyncStatusState>.empty(),
      initialState: const SyncStatusState(),
    );

    await withClock(Clock.fixed(now), () async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  PendingChangeDetailSheet.show(context, cubit, value),
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
        matchesGoldenFile('goldens/pending_change_detail_sheet_$name.png'),
      );
    });
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('detalle — con monto y fecha ($suffix)', (tester) async {
      await golden(
        tester,
        change(withAmount: true),
        'with_amount_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('detalle — sin monto ni fecha ($suffix)', (tester) async {
      await golden(
        tester,
        change(withAmount: false),
        'no_amount_$suffix',
        brightness: brightness,
      );
    });

    // Payload sin nombre: el título se queda con el tipo de entidad solo
    // ("Meta"), nunca con el nombre de la tabla.
    testWidgets('detalle — sin nombre en el payload ($suffix)', (tester) async {
      await golden(
        tester,
        PendingSyncChange.fromOperation(
          QuarantinedOperation(
            id: 'q-2',
            operation: const SyncOperation(
              tableName: 'goals',
              rowId: 'row-2',
              type: SyncOperationType.put,
              payload: {'target_minor': 250000000},
            ),
            kind: SyncFailureKind.brokenSchema,
            errorCode: 'PGRST204',
            errorMessage: 'column does not exist',
            quarantinedAt: now.subtract(const Duration(hours: 5)),
            updatedAt: now,
            attempts: 1,
          ),
        ),
        'no_label_$suffix',
        brightness: brightness,
      );
    });
  }
}
