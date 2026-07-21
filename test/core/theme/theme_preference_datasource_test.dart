import 'package:billetudo/core/theme/theme_preference_datasource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late ThemePreferenceDatasource datasource;

  setUp(() {
    // Swaps the real platform channel for an in-memory store — this is the
    // async counterpart of `SharedPreferences.setMockInitialValues`, which
    // only covers the legacy (non-async) API.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    datasource = ThemePreferenceDatasource(SharedPreferencesAsync());
  });

  group('ThemePreferenceDatasource', () {
    test('read() defaults to ThemeMode.system when nothing was saved',
        () async {
      expect(await datasource.read(), ThemeMode.system);
    });

    test('write() then read() roundtrips ThemeMode.light', () async {
      await datasource.write(ThemeMode.light);

      expect(await datasource.read(), ThemeMode.light);
    });

    test('write() then read() roundtrips ThemeMode.dark', () async {
      await datasource.write(ThemeMode.dark);

      expect(await datasource.read(), ThemeMode.dark);
    });

    test('write() then read() roundtrips ThemeMode.system', () async {
      await datasource.write(ThemeMode.system);

      expect(await datasource.read(), ThemeMode.system);
    });

    test('a later write() overrides an earlier one', () async {
      await datasource.write(ThemeMode.dark);
      await datasource.write(ThemeMode.light);

      expect(await datasource.read(), ThemeMode.light);
    });

    test('an unrecognized stored value falls back to ThemeMode.system',
        () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData(
        {'theme_mode': 'not_a_real_mode'},
      );
      datasource = ThemePreferenceDatasource(SharedPreferencesAsync());

      expect(await datasource.read(), ThemeMode.system);
    });
  });
}
