import 'package:billetudo/core/crash/sentry_redaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('redactSensitiveText', () {
    test('drops the values of a unique violation but keeps the columns', () {
      expect(
        redactSensitiveText('Key (id)=(abc-123) already exists.'),
        'Key (id)=($redactionPlaceholder) already exists.',
      );
    });

    test('keeps the constraint identifier readable', () {
      const message =
          'duplicate key value violates unique constraint "transactions_pkey"';
      expect(redactSensitiveText(message), message);
    });

    test('drops the whole failing row', () {
      expect(
        redactSensitiveText(
          'Failing row contains (1, 45000, cena con Ana, 2026-08-01).',
        ),
        'Failing row contains ($redactionPlaceholder)',
      );
    });

    test('drops sqlite statement parameters', () {
      expect(
        redactSensitiveText(
          'SqliteException(1): UNIQUE constraint failed\n'
          '  Causing statement: INSERT INTO transactions, '
          'parameters: abc-123, 45000, cena con Ana',
        ),
        'SqliteException(1): UNIQUE constraint failed\n'
        '  Causing statement: INSERT INTO transactions'
        ', parameters: $redactionPlaceholder',
      );
    });

    test('drops single-quoted literals', () {
      expect(
        redactSensitiveText(
          'invalid input value for enum entry_type: no such value',
        ),
        'invalid input value for enum entry_type: no such value',
      );
      expect(
        redactSensitiveText("value 'cena con Ana' is out of range"),
        "value '$redactionPlaceholder' is out of range",
      );
    });

    test('drops the operand of an invalid input syntax error', () {
      expect(
        redactSensitiveText('invalid input syntax for type integer: "45000"'),
        'invalid input syntax for type integer: "$redactionPlaceholder"',
      );
    });

    test('leaves a value-free message untouched', () {
      const message = 'new row violates row-level security policy';
      expect(redactSensitiveText(message), message);
    });
  });

  group('redactSentryEvent', () {
    test('redacts exception values, message and breadcrumbs', () {
      final event = SentryEvent(
        message: SentryMessage('Key (id)=(abc-123) already exists.'),
        exceptions: [
          SentryException(
            type: 'PostgrestException',
            value: 'PostgrestException(message: duplicate key value violates '
                'unique constraint "transactions_pkey", code: 23505, '
                'details: Key (id)=(abc-123) already exists.)',
          ),
        ],
        breadcrumbs: [
          Breadcrumb(
            message: 'upload failed: Failing row contains (45000, cena)',
            data: const {'sql': "WHERE note = 'cena con Ana'"},
          ),
        ],
      );

      final redacted = redactSentryEvent(event);

      expect(
        redacted.exceptions!.single.value,
        'PostgrestException(message: duplicate key value violates '
        'unique constraint "transactions_pkey", code: 23505, '
        'details: Key (id)=($redactionPlaceholder) already exists.)',
      );
      expect(redacted.exceptions!.single.type, 'PostgrestException');
      expect(
        redacted.message!.formatted,
        'Key (id)=($redactionPlaceholder) already exists.',
      );
      expect(
        redacted.breadcrumbs!.single.message,
        'upload failed: Failing row contains ($redactionPlaceholder)',
      );
      expect(
        redacted.breadcrumbs!.single.data!['sql'],
        "WHERE note = '$redactionPlaceholder'",
      );
    });

    test('leaves a safe origin context untouched', () {
      final event = SentryEvent(
        contexts: Contexts()
          ..['origin'] = {
            'detail': 'PowerSync upload quarantined a invalidData rejection '
                '(table transactions, code 23505)',
          },
      );

      expect(
        (redactSentryEvent(event).contexts['origin']
            as Map<String, dynamic>)['detail'],
        'PowerSync upload quarantined a invalidData rejection '
        '(table transactions, code 23505)',
      );
    });
  });
}
