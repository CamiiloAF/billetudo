import 'package:billetudo/core/crash/sentry_crash_reporter.dart';
import 'package:billetudo/core/crash/sentry_redaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('applySentryOptions.beforeSend', () {
    late SentryFlutterOptions options;

    setUp(() {
      options = SentryFlutterOptions();
      applySentryOptions(options);
    });

    test(
        'drops the AuthException SupabaseOperationUploader throws on '
        'purpose to make PowerSync retry a pending upload (BILLETUDO-J: it '
        'is not a crash, every guest user hits it before signing in)',
        () async {
      final event = SentryEvent(
        exceptions: [
          SentryException(
            type: 'AuthException',
            value: 'AuthException(message: No active Supabase session: '
                'cannot upload app_settings/app yet., statusCode: null, '
                'code: null)',
          ),
        ],
      );

      final result = await options.beforeSend!(event, Hint());

      expect(result, isNull);
    });

    test('keeps an AuthException with an unrelated message', () async {
      final event = SentryEvent(
        exceptions: [
          SentryException(
            type: 'AuthException',
            value: 'Invalid login credentials',
          ),
        ],
      );

      final result = await options.beforeSend!(event, Hint());

      expect(result, isNotNull);
    });

    test(
        'keeps an unrelated exception through unchanged (redaction still '
        'runs)', () async {
      final event = SentryEvent(
        exceptions: [
          SentryException(
            type: 'SqliteException',
            value: 'UNIQUE constraint failed, parameters: [abc-123]',
          ),
        ],
      );

      final result = await options.beforeSend!(event, Hint());

      expect(result, isNotNull);
      expect(
        result!.exceptions!.single.value,
        'UNIQUE constraint failed, parameters: $redactionPlaceholder',
      );
    });
  });
}
