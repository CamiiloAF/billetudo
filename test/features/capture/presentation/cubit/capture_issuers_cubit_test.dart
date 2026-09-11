import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/issuer_app.dart';
import 'package:billetudo/features/capture/domain/usecases/get_issuer_apps.dart';
import 'package:billetudo/features/capture/domain/usecases/is_notification_access_granted.dart';
import 'package:billetudo/features/capture/domain/usecases/set_issuer_listening.dart';
import 'package:billetudo/features/capture/domain/usecases/turn_off_all_issuer_listening.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_issuers_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_issuers_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

IssuerApp _issuer(String id, {required bool enabled}) => IssuerApp(
      issuerId: id,
      displayName: id,
      packageName: 'com.$id',
      installed: true,
      enabled: enabled,
    );

void main() {
  late MockNotificationCaptureRepository capture;
  late MockIssuerSettingsRepository issuers;

  setUpAll(() => registerFallbackValue(const <String>{}));

  setUp(() {
    capture = MockNotificationCaptureRepository();
    issuers = MockIssuerSettingsRepository();
    when(capture.getEnabledIssuers)
        .thenAnswer((_) async => const Right(<String>{}));
    when(() => capture.setEnabledIssuers(any()))
        .thenAnswer((_) async => const Right(unit));
    when(issuers.disableAllIssuers).thenAnswer((_) async => const Right(unit));
    when(
      () => issuers.setIssuerEnabled(
        packageName: any(named: 'packageName'),
        enabled: any(named: 'enabled'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  CaptureIssuersCubit build() => CaptureIssuersCubit(
        GetIssuerApps(capture),
        IsNotificationAccessGranted(capture),
        SetIssuerListening(capture, issuers),
        TurnOffAllIssuerListening(capture, issuers),
      );

  void stubPermission({required bool granted}) => when(
        capture.isPermissionGranted,
      ).thenAnswer((_) async => Right(granted));

  void stubApps(List<IssuerApp> apps) => when(
        capture.getInstalledIssuerApps,
      ).thenAnswer((_) async => Right(apps));

  blocTest<CaptureIssuersCubit, CaptureIssuersState>(
    'lists installed catalogued apps, every one of them off by default',
    setUp: () {
      stubPermission(granted: true);
      stubApps(<IssuerApp>[
        _issuer('nu', enabled: false),
        _issuer('nequi', enabled: false),
      ]);
    },
    build: build,
    act: (CaptureIssuersCubit cubit) => cubit.start(),
    verify: (CaptureIssuersCubit cubit) {
      expect(cubit.state.issuers, hasLength(2));
      expect(cubit.state.enabledCount, 0);
      expect(cubit.state.hasEnabled, isFalse);
    },
  );

  blocTest<CaptureIssuersCubit, CaptureIssuersState>(
    'counts how many are active, which is what the summary row states',
    setUp: () {
      stubPermission(granted: true);
      stubApps(<IssuerApp>[
        _issuer('nu', enabled: true),
        _issuer('nequi', enabled: false),
        _issuer('google_wallet', enabled: true),
      ]);
    },
    build: build,
    act: (CaptureIssuersCubit cubit) => cubit.start(),
    verify: (CaptureIssuersCubit cubit) => expect(cubit.state.enabledCount, 2),
  );

  blocTest<CaptureIssuersCubit, CaptureIssuersState>(
    'a revoked permission takes over the screen instead of showing switches '
    'that cannot capture anything',
    setUp: () {
      stubPermission(granted: false);
      stubApps(const <IssuerApp>[]);
    },
    build: build,
    act: (CaptureIssuersCubit cubit) => cubit.start(),
    verify: (CaptureIssuersCubit cubit) {
      expect(cubit.state.permissionGranted, isFalse);
      // Not even asked for: the list is meaningless without the permission.
      verifyNever(capture.getInstalledIssuerApps);
    },
  );

  blocTest<CaptureIssuersCubit, CaptureIssuersState>(
    'no installed candidate app is a legitimate state, not an error',
    setUp: () {
      stubPermission(granted: true);
      stubApps(const <IssuerApp>[]);
    },
    build: build,
    act: (CaptureIssuersCubit cubit) => cubit.start(),
    verify: (CaptureIssuersCubit cubit) {
      expect(cubit.state.hasNoInstalledApps, isTrue);
      expect(cubit.state.hasError, isFalse);
    },
  );

  blocTest<CaptureIssuersCubit, CaptureIssuersState>(
    'switching an issuer on writes the native gate and re-reads instead of '
    'trusting the tap',
    setUp: () {
      stubPermission(granted: true);
      stubApps(<IssuerApp>[_issuer('nu', enabled: false)]);
    },
    build: build,
    act: (CaptureIssuersCubit cubit) async {
      await cubit.start();
      stubApps(<IssuerApp>[_issuer('nu', enabled: true)]);
      await cubit.setEnabled(
          issuer: _issuer('nu', enabled: false), enabled: true);
    },
    verify: (CaptureIssuersCubit cubit) {
      verify(() => capture.setEnabledIssuers({'nu'})).called(1);
      expect(cubit.state.enabledCount, 1);
    },
  );

  blocTest<CaptureIssuersCubit, CaptureIssuersState>(
    '"Apagar todas" clears every issuer without revoking the system '
    'permission',
    setUp: () {
      stubPermission(granted: true);
      stubApps(<IssuerApp>[_issuer('nu', enabled: true)]);
    },
    build: build,
    act: (CaptureIssuersCubit cubit) async {
      await cubit.start();
      stubApps(<IssuerApp>[_issuer('nu', enabled: false)]);
      await cubit.turnOffAll();
    },
    verify: (CaptureIssuersCubit cubit) {
      verify(() => capture.setEnabledIssuers(const <String>{})).called(1);
      verifyNever(capture.openPermissionSettings);
      expect(cubit.state.enabledCount, 0);
      // The permission is untouched: the screen stays usable.
      expect(cubit.state.permissionGranted, isTrue);
    },
  );

  blocTest<CaptureIssuersCubit, CaptureIssuersState>(
    'a failed read surfaces as a retryable error, not as an empty catalog',
    setUp: () {
      stubPermission(granted: true);
      when(capture.getInstalledIssuerApps).thenAnswer(
          (_) async => const Left(UnexpectedFailure('channel down')));
    },
    build: build,
    act: (CaptureIssuersCubit cubit) => cubit.start(),
    verify: (CaptureIssuersCubit cubit) {
      expect(cubit.state.hasError, isTrue);
      expect(cubit.state.hasNoInstalledApps, isFalse);
    },
  );
}
