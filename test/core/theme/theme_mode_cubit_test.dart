import 'package:billetudo/core/theme/theme_mode_cubit.dart';
import 'package:billetudo/core/theme/theme_preference_datasource.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockThemePreferenceDatasource extends Mock
    implements ThemePreferenceDatasource {}

void main() {
  late MockThemePreferenceDatasource datasource;

  setUpAll(() {
    registerFallbackValue(ThemeMode.system);
  });

  setUp(() {
    datasource = MockThemePreferenceDatasource();
  });

  group('ThemeModeCubit', () {
    test('starts in ThemeMode.system before load() resolves', () async {
      final cubit = ThemeModeCubit(datasource);

      expect(cubit.state, ThemeMode.system);

      await cubit.close();
    });

    blocTest<ThemeModeCubit, ThemeMode>(
      'load() emits the persisted mode',
      setUp: () => when(datasource.read).thenAnswer((_) async => ThemeMode.dark),
      build: () => ThemeModeCubit(datasource),
      act: (cubit) => cubit.load(),
      expect: () => [ThemeMode.dark],
    );

    blocTest<ThemeModeCubit, ThemeMode>(
      'load() falls back to ThemeMode.system when nothing was persisted',
      setUp: () =>
          when(datasource.read).thenAnswer((_) async => ThemeMode.system),
      build: () => ThemeModeCubit(datasource),
      act: (cubit) => cubit.load(),
      expect: () => [ThemeMode.system],
    );

    blocTest<ThemeModeCubit, ThemeMode>(
      'setThemeMode() emits the new mode immediately',
      setUp: () => when(() => datasource.write(any()))
          .thenAnswer((_) async {}),
      build: () => ThemeModeCubit(datasource),
      act: (cubit) => cubit.setThemeMode(ThemeMode.light),
      expect: () => [ThemeMode.light],
    );

    blocTest<ThemeModeCubit, ThemeMode>(
      'setThemeMode() persists the new mode through the datasource',
      setUp: () => when(() => datasource.write(any()))
          .thenAnswer((_) async {}),
      build: () => ThemeModeCubit(datasource),
      act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
      verify: (_) => verify(() => datasource.write(ThemeMode.dark)).called(1),
    );

    test('load() does not emit once the cubit has already been closed',
        () async {
      when(datasource.read).thenAnswer((_) async => ThemeMode.dark);
      final cubit = ThemeModeCubit(datasource);
      final loadFuture = cubit.load();
      await cubit.close();

      // Must not throw `Bad state: Cannot emit new states after calling
      // close` even though `read()` resolves after `close()`.
      await loadFuture;
    });
  });
}
