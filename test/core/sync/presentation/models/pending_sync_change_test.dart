import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/presentation/models/pending_sync_change.dart';
import 'package:billetudo/core/sync/presentation/models/sync_change_kind.dart';
import 'package:flutter_test/flutter_test.dart';

/// La regla de producto de HU-08: **la jerga técnica muere aquí**. El payload
/// que llega de la cuarentena trae códigos, nombres de tabla y timestamps, y
/// ninguno de ellos puede sobrevivir el mapeo a lo que la pantalla muestra.
void main() {
  final quarantinedAt = DateTime(2026, 7, 25, 9, 30);

  QuarantinedOperation operation({
    String tableName = 'transactions',
    Map<String, dynamic>? payload,
    String? errorCode = 'PGRST204',
    String errorMessage = 'column debts.closed_at does not exist',
    int attempts = 3,
  }) =>
      QuarantinedOperation(
        id: 'q-1',
        operation: SyncOperation(
          tableName: tableName,
          rowId: 'row-1',
          type: SyncOperationType.put,
          payload: payload,
        ),
        kind: SyncFailureKind.brokenSchema,
        errorCode: errorCode,
        errorMessage: errorMessage,
        quarantinedAt: quarantinedAt,
        updatedAt: quarantinedAt,
        attempts: attempts,
      );

  group('identidad y espera', () {
    test(
        'conserva el id del registro de cuarentena (a lo que apunta el '
        'reintento), no el id de la fila afectada', () {
      final change = PendingSyncChange.fromOperation(operation());

      expect(change.id, 'q-1');
    });

    test('pendingSince es cuando se puso en cuarentena y attempts se traslada',
        () {
      final change = PendingSyncChange.fromOperation(operation());

      expect(change.pendingSince, quarantinedAt);
      expect(change.attempts, 3);
    });
  });

  group('mapeo de tabla a vocabulario del usuario', () {
    for (final (table, kind) in const [
      ('transactions', SyncChangeKind.transaction),
      ('accounts', SyncChangeKind.account),
      ('budgets', SyncChangeKind.budget),
      ('budget_categories', SyncChangeKind.budget),
      ('goals', SyncChangeKind.goal),
      ('goal_contributions', SyncChangeKind.goalContribution),
      ('debts', SyncChangeKind.debt),
      ('debt_entries', SyncChangeKind.debtEntry),
      ('scheduled_payments', SyncChangeKind.scheduledPayment),
      ('scheduled_payment_occurrences', SyncChangeKind.scheduledPayment),
      ('categories', SyncChangeKind.category),
      ('tags', SyncChangeKind.tag),
      ('transaction_tags', SyncChangeKind.tag),
      ('app_settings', SyncChangeKind.settings),
    ]) {
      test('$table se traduce a $kind', () {
        expect(
          PendingSyncChange.fromOperation(operation(tableName: table)).kind,
          kind,
        );
      });
    }

    test('una tabla no mapeada degrada a "other", nunca expone el nombre', () {
      final change = PendingSyncChange.fromOperation(
        operation(tableName: 'goal_contribution_streaks'),
      );

      expect(change.kind, SyncChangeKind.other);
      expect(change.label, isNull);
    });
  });

  group('nada técnico sobrevive al mapeo', () {
    test(
        'el código del backend y el mensaje crudo no llegan a ningún campo '
        'visible', () {
      final change = PendingSyncChange.fromOperation(
        operation(
          tableName: 'debts',
          payload: const {'name': 'Préstamo a Ana', 'amount_minor': 1500000},
        ),
      );

      final visible = [change.label, change.currencyCode].join(' ');
      expect(visible, isNot(contains('PGRST204')));
      expect(visible, isNot(contains('closed_at')));
      expect(visible, isNot(contains('debts')));
    });

    test(
        'un payload que trae basura técnica en columnas que no se leen no '
        'aporta label', () {
      final change = PendingSyncChange.fromOperation(
        operation(
          tableName: 'transactions',
          payload: const {'error_code': 'PGRST204', 'table': 'transactions'},
        ),
      );

      expect(change.label, isNull);
    });
  });

  group('label: el nombre humano de la fila', () {
    test('prefiere "name" sobre el resto', () {
      final change = PendingSyncChange.fromOperation(
        operation(
          payload: const {
            'name': 'Mercado',
            'note': 'Café con Ana',
            'counterparty': 'Ana',
          },
        ),
      );

      expect(change.label, 'Mercado');
    });

    test('cae a "note" y luego a "counterparty"', () {
      expect(
        PendingSyncChange.fromOperation(
          operation(payload: const {'note': 'Café con Ana'}),
        ).label,
        'Café con Ana',
      );
      expect(
        PendingSyncChange.fromOperation(
          operation(payload: const {'counterparty': 'Ana'}),
        ).label,
        'Ana',
      );
    });

    test('recorta espacios y descarta un texto en blanco', () {
      expect(
        PendingSyncChange.fromOperation(
          operation(payload: const {'name': '  Mercado  '}),
        ).label,
        'Mercado',
      );
      expect(
        PendingSyncChange.fromOperation(
          operation(payload: const {'name': '   ', 'note': 'Café'}),
        ).label,
        'Café',
      );
    });

    test('sin payload no inventa nada: label null', () {
      expect(PendingSyncChange.fromOperation(operation()).label, isNull);
    });
  });

  group('dinero: enteros en centavos, jamás doubles', () {
    test('amount_minor entero se traslada tal cual', () {
      final change = PendingSyncChange.fromOperation(
        operation(payload: const {'amount_minor': 1800000}),
      );

      expect(change.amountMinor, 1800000);
      expect(change.amountMinor, isA<int>());
    });

    test('un amount_minor que llega como texto se parsea a entero', () {
      expect(
        PendingSyncChange.fromOperation(
          operation(payload: const {'amount_minor': '1234'}),
        ).amountMinor,
        1234,
      );
    });

    test('un amount_minor que llega como num se trunca a entero', () {
      expect(
        PendingSyncChange.fromOperation(
          operation(payload: const {'amount_minor': 1234.0}),
        ).amountMinor,
        1234,
      );
    });

    test('sin monto queda null, no 0 (0 sería un monto real)', () {
      expect(
        PendingSyncChange.fromOperation(
          operation(payload: const {'name': 'Mercado'}),
        ).amountMinor,
        isNull,
      );
    });

    test('la moneda viaja para poder formatear el monto', () {
      expect(
        PendingSyncChange.fromOperation(
          operation(payload: const {'amount_minor': 100, 'currency': 'COP'}),
        ).currencyCode,
        'COP',
      );
    });
  });

  group('fechas: segundos unix (decisión #15), no milisegundos', () {
    test('"date" se interpreta como segundos unix', () {
      final moment = DateTime.utc(2026, 7, 12, 15);
      final change = PendingSyncChange.fromOperation(
        operation(
          payload: {'date': moment.millisecondsSinceEpoch ~/ 1000},
        ),
      );

      expect(change.occurredAt?.toUtc(), moment);
    });

    test('"entry_date" es el respaldo cuando no hay "date"', () {
      final moment = DateTime.utc(2026, 7, 12);
      final change = PendingSyncChange.fromOperation(
        operation(
          tableName: 'debt_entries',
          payload: {'entry_date': moment.millisecondsSinceEpoch ~/ 1000},
        ),
      );

      expect(change.occurredAt?.toUtc(), moment);
    });

    test('sin fecha queda null', () {
      expect(PendingSyncChange.fromOperation(operation()).occurredAt, isNull);
    });
  });
}
