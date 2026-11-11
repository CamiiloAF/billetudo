import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/data/datasources/capture_background_preference_datasource.dart';
import 'package:billetudo/features/capture/data/repositories/capture_background_preferences_repository_impl.dart';
import 'package:billetudo/features/capture/domain/repositories/capture_background_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The two per-device dates behind HU-09 survive a repository **instance**
/// change and never leak into each other: "Ahora no" must still be in effect
/// after the app is killed and reopened, and latching the configured date must
/// not be undone or pushed forward by a snooze.
///
/// Each "new repository" below opens a fresh datasource over the same in-memory
/// store, which is exactly what the app does on next launch (same
/// `SharedPreferences` file, new objects). That is the part the use-case test
/// cannot prove: it mocks the repository away.
void main() {
  CaptureBackgroundPreferencesRepository buildRepository() =>
      CaptureBackgroundPreferencesRepositoryImpl(
        CaptureBackgroundPreferenceDatasource(SharedPreferencesAsync()),
        const NoopCrashReporter(),
      );

  DateTime? valueOf(Result<DateTime?> result) =>
      result.getOrElse((Failure f) => throw StateError(f.message));

  setUp(() {
    // The async counterpart of `SharedPreferences.setMockInitialValues`, which
    // only covers the legacy (non-async) API.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('CaptureBackgroundPreferencesRepositoryImpl', () {
    test('a fresh install has no configured date and no snooze', () async {
      final CaptureBackgroundPreferencesRepository repository =
          buildRepository();

      expect(valueOf(await repository.configuredAt()), isNull);
      expect(valueOf(await repository.snoozedUntil()), isNull);
    });

    test('the configured mark round-trips to the exact millisecond', () async {
      final DateTime at = DateTime(2026, 11, 7, 9, 19, 42, 123);
      final CaptureBackgroundPreferencesRepository repository =
          buildRepository();

      expect((await repository.markConfigured(at)).isRight(), isTrue);

      expect(valueOf(await repository.configuredAt()), at);
    });

    test('a snooze survives a brand new repository instance', () async {
      final DateTime until = DateTime(2026, 11, 24, 18, 30);
      final CaptureBackgroundPreferencesRepository first = buildRepository();

      expect((await first.snoozeUntil(until)).isRight(), isTrue);

      // Same store, new objects: the next app launch.
      final CaptureBackgroundPreferencesRepository second = buildRepository();
      expect(valueOf(await second.snoozedUntil()), until);
    });

    test('a snooze never touches the configured date or the other way around',
        () async {
      final DateTime configured = DateTime(2026, 10, 1, 8);
      final DateTime until = DateTime(2026, 11, 24, 18, 30);
      final CaptureBackgroundPreferencesRepository repository =
          buildRepository();
      await repository.markConfigured(configured);

      await repository.snoozeUntil(until);

      expect(valueOf(await repository.configuredAt()), configured);
      expect(valueOf(await repository.snoozedUntil()), until);
    });

    test('a snooze replaces the previous one instead of accumulating',
        () async {
      final CaptureBackgroundPreferencesRepository repository =
          buildRepository();
      await repository.snoozeUntil(DateTime(2026, 11, 20));
      final DateTime later = DateTime(2026, 12, 1);

      await repository.snoozeUntil(later);

      expect(valueOf(await repository.snoozedUntil()), later);
    });

    test('the mark written first is the one that stays on this device',
        () async {
      final DateTime first = DateTime(2026, 10, 1, 8);
      final CaptureBackgroundPreferencesRepository repository =
          buildRepository();
      await repository.markConfigured(first);

      // `markConfigured` is a plain write: the once-only rule belongs to
      // `MarkCaptureConfigured`, which checks before calling this. This test
      // pins the store, not the rule.
      expect(valueOf(await buildRepository().configuredAt()), first);
    });
  });
}
