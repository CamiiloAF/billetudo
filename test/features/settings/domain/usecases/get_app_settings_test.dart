import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/domain/usecases/get_app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'app_settings_repository_mock.dart';

void main() {
  late MockAppSettingsRepository repository;
  late GetAppSettings getAppSettings;

  setUp(() {
    repository = MockAppSettingsRepository();
    getAppSettings = GetAppSettings(repository);
  });

  test('HU-06: forwards the repository stream unchanged', () {
    const settings =
        AppSettings(zeroBasedEnabled: true, categoriesSeeded: false);
    when(() => repository.watchSettings())
        .thenAnswer((_) => Stream.value(const Right(settings)));

    final stream = getAppSettings();

    expect(stream, emits(const Right<Object, AppSettings>(settings)));
  });

  test('propagates a repository failure', () {
    when(() => repository.watchSettings()).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('boom'))),
    );

    final stream = getAppSettings();

    expect(stream, emits(isA<Left<Failure, AppSettings>>()));
  });
}
