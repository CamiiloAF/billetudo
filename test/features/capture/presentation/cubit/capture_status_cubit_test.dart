import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/issuer_app.dart';
import 'package:billetudo/features/capture/domain/usecases/get_issuer_apps.dart';
import 'package:billetudo/features/capture/domain/usecases/is_notification_access_granted.dart';
import 'package:billetudo/features/capture/domain/usecases/is_notification_capture_supported.dart';
import 'package:billetudo/features/capture/domain/usecases/turn_off_all_issuer_listening.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_status_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_status_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

const IssuerApp _nu = IssuerApp(
  issuerId: 'nu',
  displayName: 'Nu',
  packageName: 'com.nu.production',
  installed: true,
  enabled: true,
);

void main() {
  late MockNotificationCaptureRepository capture;
  late MockIssuerSettingsRepository issuers;

  setUpAll(() => registerFallbackValue(const <String>{}));

  setUp(() {
    capture = MockNotificationCaptureRepository();
    issuers = MockIssuerSettingsRepository();
    when(() => capture.isSupported).thenReturn(true);
    when(() => capture.setEnabledIssuers(any()))
        .thenAnswer((_) async => const Right(unit));
    when(issuers.disableAllIssuers).thenAnswer((_) async => const Right(unit));
  });

  CaptureStatusCubit build() => CaptureStatusCubit(
        IsNotificationCaptureSupported(capture),
        IsNotificationAccessGranted(capture),
        GetIssuerApps(capture),
        TurnOffAllIssuerListening(capture, issuers),
      );

  blocTest<CaptureStatusCubit, CaptureStatusState>(
    'off Android the row reports unsupported and never asks the system '
    'anything: the feature must not surface there at all',
    setUp: () => when(() => capture.isSupported).thenReturn(false),
    build: build,
    act: (CaptureStatusCubit cubit) => cubit.start(),
    verify: (CaptureStatusCubit cubit) {
      expect(cubit.state.isSupported, isFalse);
      verifyNever(capture.isPermissionGranted);
    },
  );

  blocTest<CaptureStatusCubit, CaptureStatusState>(
    'a granted permission with no issuer on is NOT listening: the row must '
    'not imply a coverage that does not exist',
    setUp: () {
      when(capture.isPermissionGranted)
          .thenAnswer((_) async => const Right(true));
      when(capture.getInstalledIssuerApps)
          .thenAnswer((_) async => const Right(<IssuerApp>[]));
    },
    build: build,
    act: (CaptureStatusCubit cubit) => cubit.start(),
    verify: (CaptureStatusCubit cubit) {
      expect(cubit.state.permissionGranted, isTrue);
      expect(cubit.state.enabledCount, 0);
      expect(cubit.state.isListening, isFalse);
    },
  );

  blocTest<CaptureStatusCubit, CaptureStatusState>(
    'listening only when the permission is granted AND an issuer is on',
    setUp: () {
      when(capture.isPermissionGranted)
          .thenAnswer((_) async => const Right(true));
      when(capture.getInstalledIssuerApps)
          .thenAnswer((_) async => const Right(<IssuerApp>[_nu]));
    },
    build: build,
    act: (CaptureStatusCubit cubit) => cubit.start(),
    verify: (CaptureStatusCubit cubit) =>
        expect(cubit.state.isListening, isTrue),
  );

  blocTest<CaptureStatusCubit, CaptureStatusState>(
    'a revocation done from Android shows up on the next refresh, because '
    'the state is re-asked and never read from a flag',
    setUp: () {
      when(capture.isPermissionGranted)
          .thenAnswer((_) async => const Right(true));
      when(capture.getInstalledIssuerApps)
          .thenAnswer((_) async => const Right(<IssuerApp>[_nu]));
    },
    build: build,
    act: (CaptureStatusCubit cubit) async {
      await cubit.start();
      when(capture.isPermissionGranted)
          .thenAnswer((_) async => const Right(false));
      await cubit.refresh();
    },
    verify: (CaptureStatusCubit cubit) {
      expect(cubit.state.permissionGranted, isFalse);
      expect(cubit.state.isListening, isFalse);
    },
  );

  blocTest<CaptureStatusCubit, CaptureStatusState>(
    "the app's own kill switch stops capture without revoking the system "
    'permission',
    setUp: () {
      when(capture.isPermissionGranted)
          .thenAnswer((_) async => const Right(true));
      when(capture.getInstalledIssuerApps)
          .thenAnswer((_) async => const Right(<IssuerApp>[_nu]));
    },
    build: build,
    act: (CaptureStatusCubit cubit) async {
      await cubit.start();
      when(capture.getInstalledIssuerApps)
          .thenAnswer((_) async => const Right(<IssuerApp>[]));
      await cubit.stopListening();
    },
    verify: (CaptureStatusCubit cubit) {
      verify(() => capture.setEnabledIssuers(const <String>{})).called(1);
      verifyNever(capture.openPermissionSettings);
      expect(cubit.state.isListening, isFalse);
      expect(cubit.state.permissionGranted, isTrue);
    },
  );
}
