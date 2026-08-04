import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_cubit.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_state.dart';
import 'package:billetudo/core/sync/presentation/models/pending_sync_change.dart';
import 'package:billetudo/core/sync/presentation/widgets/sheets/pending_change_detail_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../pump_sync.dart';

class MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// El detalle de un cambio trabado (`r1qQYc`). Prohibido aquí: códigos,
/// nombres de tabla y timestamps ISO — esos viven solo en el registro técnico.
/// Tampoco hay "Descartar": nada en este flujo destruye datos que solo existen
/// en este teléfono.
void main() {
  final now = DateTime.now();

  PendingSyncChange change({
    String tableName = 'transactions',
    Map<String, dynamic>? payload,
    int attempts = 8,
    Duration waiting = const Duration(days: 3),
  }) =>
      PendingSyncChange.fromOperation(
        QuarantinedOperation(
          id: 'q-1',
          operation: SyncOperation(
            tableName: tableName,
            rowId: 'row-1',
            type: SyncOperationType.put,
            payload: payload,
          ),
          kind: SyncFailureKind.brokenSchema,
          errorCode: 'PGRST204',
          errorMessage: 'column transactions.foo does not exist',
          quarantinedAt: now.subtract(waiting),
          updatedAt: now,
          attempts: attempts,
        ),
      );

  late MockSyncStatusCubit cubit;

  setUp(() {
    cubit = MockSyncStatusCubit();
    when(() => cubit.retryOne(any())).thenAnswer((_) async {});
    whenListen(
      cubit,
      const Stream<SyncStatusState>.empty(),
      initialState: const SyncStatusState(),
    );
  });

  Future<void> pumpSheet(WidgetTester tester, PendingSyncChange value) =>
      tester.pumpSyncWidget(
        BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: PendingChangeDetailSheet(change: value),
        ),
      );

  testWidgets('nombra el cambio en el idioma del usuario', (tester) async {
    await pumpSheet(
      tester,
      change(payload: const {'note': 'Café con Ana'}),
    );

    expect(find.text('Movimiento · Café con Ana'), findsOneWidget);
  });

  testWidgets(
      'el monto se formatea desde los centavos, sin decimales '
      'inventados', (tester) async {
    await pumpSheet(
      tester,
      change(
        payload: const {
          'note': 'Café con Ana',
          'amount_minor': 1800000,
          'currency': 'COP',
        },
      ),
    );

    expect(find.textContaining('18.000'), findsOneWidget);
  });

  testWidgets('dice cuánto lleva esperando y cuántos intentos van',
      (tester) async {
    await pumpSheet(tester, change());

    expect(find.text('Lleva 3 días esperando'), findsOneWidget);
    expect(find.text('8 intentos de subida'), findsOneWidget);
  });

  testWidgets('un solo intento va en singular', (tester) async {
    await pumpSheet(tester, change(attempts: 1));

    expect(find.text('1 intento de subida'), findsOneWidget);
  });

  testWidgets('nombra el riesgo sin culpar al usuario', (tester) async {
    await pumpSheet(tester, change());

    expect(
      find.text(
        'La nube todavía no tiene copia de este cambio: '
        'si reinstalas la app o cambias de teléfono, no volvería.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('NO filtra código, tabla ni timestamp ISO', (tester) async {
    await pumpSheet(
      tester,
      change(
        tableName: 'goal_contributions',
        payload: const {'name': 'Vacaciones'},
      ),
    );

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .join(' | ');

    expect(texts, contains('Aporte a meta · Vacaciones'));
    expect(texts, isNot(contains('goal_contributions')));
    expect(texts, isNot(contains('PGRST204')));
    expect(texts, isNot(contains('does not exist')));
    expect(texts, isNot(contains('T00:')));
  });

  testWidgets('"Reintentar" pide el reintento de ESE cambio', (tester) async {
    await pumpSheet(tester, change());

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    verify(() => cubit.retryOne('q-1')).called(1);
  });

  testWidgets('no ofrece "Descartar" en ninguna variante', (tester) async {
    await pumpSheet(tester, change(payload: const {'note': 'Café con Ana'}));

    expect(find.textContaining('Descartar'), findsNothing);
    expect(find.textContaining('Eliminar'), findsNothing);
    expect(find.textContaining('Borrar'), findsNothing);
  });

  testWidgets('ofrece la entrada al registro técnico como acción secundaria',
      (tester) async {
    await pumpSheet(tester, change());

    expect(find.text('Registro técnico'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });
}
