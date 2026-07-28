import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:billetudo/core/sync/data/datasources/sync_error_classifier.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// The classifier is the single decision point between "retry this write" and
/// "take it out of the queue". Getting it wrong in either direction is
/// expensive: retrying a write that can never succeed blocks the FIFO upload
/// queue for every table (the `debts.closed_at`/`PGRST204` incident: three
/// days blocked, 89 unsynced changes lost), and quarantining a write that
/// would have succeeded delays real user data.
void main() {
  PostgrestException error(String? code) =>
      PostgrestException(message: 'boom', code: code);

  group('brokenSchema — the app shipped ahead of the database migration', () {
    // PGRST204 is the exact code from the incident (Sentry BILLETUDO-2):
    // "Could not find the 'closed_at' column of 'debts' in the schema cache".
    for (final code in ['PGRST204', 'PGRST205', '42703', '42P01']) {
      test('$code se clasifica como brokenSchema y es permanente', () {
        final kind = SyncErrorClassifier.classify(error(code));

        expect(kind, SyncFailureKind.brokenSchema);
        expect(kind.isPermanent, isTrue);
        expect(kind.isTransient, isFalse);
      });
    }
  });

  group('invalidData — el contenido de la escritura fue rechazado', () {
    final cases = <String, String>{
      '22007': 'invalid_datetime_format',
      '22003': 'numeric_value_out_of_range',
      '22P02': 'invalid_text_representation',
      '23503': 'foreign_key_violation',
      '23505': 'unique_violation',
      '23502': 'not_null_violation',
      '42501': 'insufficient_privilege (RLS)',
    };
    cases.forEach((code, description) {
      test('$code ($description) se clasifica como invalidData', () {
        final kind = SyncErrorClassifier.classify(error(code));

        expect(kind, SyncFailureKind.invalidData);
        expect(kind.isPermanent, isTrue);
      });
    });
  });

  group('transient — vale la pena reintentar', () {
    test('cualquier error que no sea PostgrestException', () {
      expect(
        SyncErrorClassifier.classify(const SocketException('no network')),
        SyncFailureKind.transient,
      );
      expect(
        SyncErrorClassifier.classify(StateError('unexpected')),
        SyncFailureKind.transient,
      );
      expect(
        SyncErrorClassifier.classify(Exception('boom')),
        SyncFailureKind.transient,
      );
    });

    test('PostgrestException sin código', () {
      expect(
        SyncErrorClassifier.classify(error(null)),
        SyncFailureKind.transient,
      );
    });

    test('PGRST301 (JWT vencido): solo hace falta un token nuevo', () {
      expect(
        SyncErrorClassifier.classify(error('PGRST301')),
        SyncFailureKind.transient,
      );
    });

    for (final code in ['408', '429']) {
      test('$code (timeout / rate limit) es transitorio', () {
        expect(
          SyncErrorClassifier.classify(error(code)),
          SyncFailureKind.transient,
        );
      });
    }

    for (final code in ['500', '502', '503', '504', '599']) {
      test('$code (backend caído) es transitorio', () {
        expect(
          SyncErrorClassifier.classify(error(code)),
          SyncFailureKind.transient,
        );
      });
    }

    test('un código desconocido es transitorio, no se descarta el dato', () {
      // Elegir "transitorio" ante lo desconocido es deliberado: perder una
      // escritura por un código que no entendemos sería peor que reintentarla.
      expect(
        SyncErrorClassifier.classify(error('WEIRD-CODE')),
        SyncFailureKind.transient,
      );
    });

    test('un 4xx que no es 42501 no se toma como permiso denegado', () {
      expect(
        SyncErrorClassifier.classify(error('400')),
        SyncFailureKind.transient,
      );
      expect(
        SyncErrorClassifier.classify(error('404')),
        SyncFailureKind.transient,
      );
    });
  });

  group('los patrones de clase SQLSTATE no se pasan de largo', () {
    test('225011 (seis dígitos) no cuenta como 22xxx', () {
      expect(
        SyncErrorClassifier.classify(error('225011')),
        SyncFailureKind.transient,
      );
    });

    test('2250 (cuatro dígitos) no cuenta como 22xxx', () {
      expect(
        SyncErrorClassifier.classify(error('2250')),
        SyncFailureKind.transient,
      );
    });

    test('425011 no se confunde con 42501', () {
      expect(
        SyncErrorClassifier.classify(error('425011')),
        SyncFailureKind.transient,
      );
    });
  });

  group('isConnectivityFailure — allow-list de "nunca llegamos al backend"',
      () {
    // Es la línea de la que depende el watchdog: lo que entra aquí no cuenta
    // para la cuarentena, así que un usuario sin red o un backend caído
    // acumulan reintentos legítimos sin que nada se saque de la cola.
    final connectivityFailures = <String, Object>{
      'SocketException': const SocketException('network is unreachable'),
      'TlsException': const TlsException('handshake failed'),
      'HttpException': const HttpException('connection closed'),
      'http.ClientException': http.ClientException('connection closed'),
      'TimeoutException':
          TimeoutException('no answer', const Duration(seconds: 30)),
      'AuthException': const AuthException('refresh token expired'),
      'PostgrestException PGRST301':
          const PostgrestException(message: 'jwt expired', code: 'PGRST301'),
      'PostgrestException 408':
          const PostgrestException(message: 'timeout', code: '408'),
    };

    connectivityFailures.forEach((description, failure) {
      test('$description es fallo de conectividad', () {
        expect(SyncErrorClassifier.isConnectivityFailure(failure), isTrue);
      });
    });

    test('un SocketException con OSError también entra', () {
      expect(
        SyncErrorClassifier.isConnectivityFailure(
          const SocketException('failed host lookup', osError: OSError('', 8)),
        ),
        isTrue,
      );
    });
  });

  group('isConnectivityFailure — lo que NO está en la allow-list sí cuenta',
      () {
    // La regla es allow-list a propósito: la inversa ("contar solo lo que
    // reconocemos como respuesta del servidor") dejaría abierto el agujero
    // original — un fallo determinista del cliente no es un problema de red y
    // volvería a bloquear la cola FIFO para siempre.
    final countedFailures = <String, Object>{
      'una fila que no serializa': JsonUnsupportedObjectError(Object()),
      'un bug del uploader (StateError)': StateError('unexpected null'),
      'ArgumentError': ArgumentError('bad payload'),
      'FormatException': const FormatException('not json'),
      'un Exception genérico': Exception('boom'),
      'PGRST204 (esquema roto)':
          const PostgrestException(message: 'no column', code: 'PGRST204'),
      '23503 (FK violada)':
          const PostgrestException(message: 'fk', code: '23503'),
      '503 (el backend respondió, aunque mal)':
          const PostgrestException(message: 'down', code: '503'),
      '429 (rate limit)':
          const PostgrestException(message: 'slow down', code: '429'),
      'PostgrestException sin código': const PostgrestException(message: 'x'),
    };

    countedFailures.forEach((description, failure) {
      test('$description NO es fallo de conectividad', () {
        expect(SyncErrorClassifier.isConnectivityFailure(failure), isFalse);
      });
    });

    test(
        'un 429 es transitorio pero SÍ cuenta: el backend respondió, y esa es '
        'la diferencia que el watchdog necesita', () {
      const rateLimited = PostgrestException(message: 'slow', code: '429');

      expect(
          SyncErrorClassifier.classify(rateLimited), SyncFailureKind.transient);
      expect(SyncErrorClassifier.isConnectivityFailure(rateLimited), isFalse);
    });

    test('PGRST301 es transitorio Y de conectividad: no cuenta dos veces', () {
      const expired = PostgrestException(message: 'jwt', code: 'PGRST301');

      expect(SyncErrorClassifier.classify(expired), SyncFailureKind.transient);
      expect(SyncErrorClassifier.isConnectivityFailure(expired), isTrue);
    });
  });

  group('codeOf', () {
    test('devuelve el código del PostgrestException', () {
      expect(SyncErrorClassifier.codeOf(error('PGRST204')), 'PGRST204');
    });

    test('devuelve null para un PostgrestException sin código', () {
      expect(SyncErrorClassifier.codeOf(error(null)), isNull);
    });

    test('devuelve null para cualquier otro error', () {
      expect(
        SyncErrorClassifier.codeOf(const SocketException('no network')),
        isNull,
      );
    });
  });
}
