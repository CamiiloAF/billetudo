import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'usecase_mocks.dart';

void main() {
  late MockGetAppSettings getAppSettings;
  late MockSetZeroBasedEnabled setZeroBasedEnabled;

  const enabledSettings = AppSettings(zeroBasedEnabled: true);

  setUp(() {
    getAppSettings = MockGetAppSettings();
    setZeroBasedEnabled = MockSetZeroBasedEnabled();
  });

  AppSettingsCubit build() =>
      AppSettingsCubit(getAppSettings, setZeroBasedEnabled);

  blocTest<AppSettingsCubit, AppSettingsState>(
    'HU-06: emits the settings the use case streams',
    setUp: () => when(getAppSettings.call)
        .thenAnswer((_) => Stream.value(const Right(enabledSettings))),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [const AppSettingsState(settings: enabledSettings)],
  );

  blocTest<AppSettingsCubit, AppSettingsState>(
    'a stream failure is swallowed: the last good state stays',
    setUp: () => when(getAppSettings.call).thenAnswer(
      (_) => Stream.fromIterable([
        const Right(enabledSettings),
        const Left(DatabaseFailure('boom')),
      ]),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    expect: () => [const AppSettingsState(settings: enabledSettings)],
  );

  blocTest<AppSettingsCubit, AppSettingsState>(
    'setZeroBasedEnabled delegates to the use case instead of emitting '
    'directly: the stream is the source of truth',
    setUp: () => when(() => setZeroBasedEnabled(true))
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (cubit) => cubit.setZeroBasedEnabled(true),
    expect: () => <AppSettingsState>[],
    verify: (_) => verify(() => setZeroBasedEnabled(true)).called(1),
  );
}
