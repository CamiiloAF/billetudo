import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/usecases/is_notification_access_granted.dart';
import 'package:billetudo/features/capture/domain/usecases/open_notification_access_settings.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_permission_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_permission_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

void main() {
  late MockNotificationCaptureRepository repository;
  late IsNotificationAccessGranted isGranted;
  late OpenNotificationAccessSettings openSettings;

  setUp(() {
    repository = MockNotificationCaptureRepository();
    isGranted = IsNotificationAccessGranted(repository);
    openSettings = OpenNotificationAccessSettings(repository);
    when(repository.openPermissionSettings)
        .thenAnswer((_) async => const Right(unit));
  });

  void stubGranted({required bool granted}) => when(
        repository.isPermissionGranted,
      ).thenAnswer((_) async => Right(granted));

  blocTest<CapturePermissionCubit, CapturePermissionState>(
    'starts on the explainer: the user never meets Android warning cold',
    setUp: () => stubGranted(granted: false),
    build: () => CapturePermissionCubit(isGranted, openSettings),
    act: (CapturePermissionCubit cubit) => cubit.start(),
    verify: (CapturePermissionCubit cubit) {
      expect(cubit.state.view, CapturePermissionView.explainer);
      expect(cubit.state.granted, isFalse);
    },
  );

  blocTest<CapturePermissionCubit, CapturePermissionState>(
    're-asks the system on return and does not assume the permission was '
    'granted just because the user went to Ajustes',
    setUp: () => stubGranted(granted: false),
    build: () => CapturePermissionCubit(isGranted, openSettings),
    act: (CapturePermissionCubit cubit) async {
      await cubit.start();
      await cubit.openSettings();
      await cubit.recheck();
    },
    verify: (CapturePermissionCubit cubit) {
      expect(cubit.state.granted, isFalse);
      expect(cubit.state.view, CapturePermissionView.notGranted);
      // Asked on entry and again on return, never cached.
      verify(repository.isPermissionGranted).called(2);
    },
  );

  blocTest<CapturePermissionCubit, CapturePermissionState>(
    'reports granted when the system says so, which is what sends the user '
    'on to picking issuers',
    setUp: () => stubGranted(granted: true),
    build: () => CapturePermissionCubit(isGranted, openSettings),
    act: (CapturePermissionCubit cubit) async {
      await cubit.openSettings();
      await cubit.recheck();
    },
    verify: (CapturePermissionCubit cubit) {
      expect(cubit.state.granted, isTrue);
      // Never the off state when it is actually on.
      expect(cubit.state.view, CapturePermissionView.explainer);
    },
  );

  blocTest<CapturePermissionCubit, CapturePermissionState>(
    'stays on the explainer for someone who never left: the off state is not '
    'shown as a complaint about a decision that was never made',
    setUp: () => stubGranted(granted: false),
    build: () => CapturePermissionCubit(isGranted, openSettings),
    act: (CapturePermissionCubit cubit) async {
      await cubit.start();
      await cubit.recheck();
    },
    verify: (CapturePermissionCubit cubit) =>
        expect(cubit.state.view, CapturePermissionView.explainer),
  );

  blocTest<CapturePermissionCubit, CapturePermissionState>(
    'a failed check reads as not granted rather than claiming coverage',
    setUp: () => when(repository.isPermissionGranted)
        .thenAnswer((_) async => const Left(UnexpectedFailure('no channel'))),
    build: () => CapturePermissionCubit(isGranted, openSettings),
    act: (CapturePermissionCubit cubit) => cubit.start(),
    verify: (CapturePermissionCubit cubit) =>
        expect(cubit.state.granted, isFalse),
  );

  blocTest<CapturePermissionCubit, CapturePermissionState>(
    '"Ver cómo funciona" goes back to the explainer without leaving',
    setUp: () => stubGranted(granted: false),
    build: () => CapturePermissionCubit(isGranted, openSettings),
    act: (CapturePermissionCubit cubit) async {
      await cubit.openSettings();
      await cubit.recheck();
      cubit.showExplainer();
    },
    verify: (CapturePermissionCubit cubit) =>
        expect(cubit.state.view, CapturePermissionView.explainer),
  );
}
