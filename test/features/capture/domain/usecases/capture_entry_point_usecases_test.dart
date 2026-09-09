import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/issuer_app.dart';
import 'package:billetudo/features/capture/domain/usecases/mark_notification_capture_offered.dart';
import 'package:billetudo/features/capture/domain/usecases/set_issuer_listening.dart';
import 'package:billetudo/features/capture/domain/usecases/should_offer_notification_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/turn_off_all_issuer_listening.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

const IssuerApp _nu = IssuerApp(
  issuerId: 'nu',
  displayName: 'Nu',
  packageName: 'com.nu.production',
  installed: true,
  enabled: false,
);

void main() {
  late MockNotificationCaptureRepository capture;
  late MockIssuerSettingsRepository issuers;
  late MockCaptureOfferRepository offer;

  setUpAll(() => registerFallbackValue(const <String>{}));

  setUp(() {
    capture = MockNotificationCaptureRepository();
    issuers = MockIssuerSettingsRepository();
    offer = MockCaptureOfferRepository();
  });

  void stubEnabled(Set<String> enabled) {
    when(capture.getEnabledIssuers).thenAnswer((_) async => Right(enabled));
    when(() => capture.setEnabledIssuers(any()))
        .thenAnswer((_) async => const Right(unit));
    when(
      () => issuers.setIssuerEnabled(
        packageName: any(named: 'packageName'),
        enabled: any(named: 'enabled'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  }

  group('SetIssuerListening', () {
    test(
        'adds the issuer to the native set, which is the gate that '
        'actually stops or starts capture', () async {
      stubEnabled(const <String>{'nequi'});

      await SetIssuerListening(capture, issuers)(issuer: _nu, enabled: true);

      verify(() => capture.setEnabledIssuers({'nequi', 'nu'})).called(1);
    });

    test(
        'mirrors into the local catalog by packageName, so the inbox does '
        'not keep saying there are no issuers', () async {
      stubEnabled(const <String>{});

      await SetIssuerListening(capture, issuers)(issuer: _nu, enabled: true);

      verify(
        () => issuers.setIssuerEnabled(
          packageName: 'com.nu.production',
          enabled: true,
        ),
      ).called(1);
    });

    test('turning one off removes only that issuer', () async {
      stubEnabled(const <String>{'nu', 'nequi'});

      await SetIssuerListening(capture, issuers)(issuer: _nu, enabled: false);

      verify(() => capture.setEnabledIssuers({'nequi'})).called(1);
    });

    test(
        'does not mirror when the native write failed: a switch that did '
        'not move must not look like it did', () async {
      when(capture.getEnabledIssuers)
          .thenAnswer((_) async => const Right(<String>{}));
      when(() => capture.setEnabledIssuers(any()))
          .thenAnswer((_) async => const Left(UnexpectedFailure('nope')));

      final Result<Unit> result = await SetIssuerListening(capture, issuers)(
          issuer: _nu, enabled: true);

      expect(result.isLeft(), isTrue);
      verifyNever(
        () => issuers.setIssuerEnabled(
          packageName: any(named: 'packageName'),
          enabled: any(named: 'enabled'),
        ),
      );
    });
  });

  group('TurnOffAllIssuerListening', () {
    test(
        'empties the native set and the local catalog in one action, '
        'without touching the system permission', () async {
      when(() => capture.setEnabledIssuers(any()))
          .thenAnswer((_) async => const Right(unit));
      when(issuers.disableAllIssuers)
          .thenAnswer((_) async => const Right(unit));

      await TurnOffAllIssuerListening(capture, issuers)();

      verify(() => capture.setEnabledIssuers(const <String>{})).called(1);
      verify(issuers.disableAllIssuers).called(1);
      verifyNever(capture.openPermissionSettings);
    });
  });

  group('ShouldOfferNotificationCapture', () {
    test(
        'offers on Android when it was never offered and the permission is '
        'not granted', () async {
      when(() => capture.isSupported).thenReturn(true);
      when(offer.hasBeenOffered).thenAnswer((_) async => const Right(false));
      when(capture.isPermissionGranted)
          .thenAnswer((_) async => const Right(false));

      expect(await ShouldOfferNotificationCapture(capture, offer)(), isTrue);
    });

    test('never offers twice', () async {
      when(() => capture.isSupported).thenReturn(true);
      when(offer.hasBeenOffered).thenAnswer((_) async => const Right(true));

      expect(await ShouldOfferNotificationCapture(capture, offer)(), isFalse);
      verifyNever(capture.isPermissionGranted);
    });

    test('does not offer what the user already granted', () async {
      when(() => capture.isSupported).thenReturn(true);
      when(offer.hasBeenOffered).thenAnswer((_) async => const Right(false));
      when(capture.isPermissionGranted)
          .thenAnswer((_) async => const Right(true));

      expect(await ShouldOfferNotificationCapture(capture, offer)(), isFalse);
    });

    test('never offers off Android, where the permission cannot exist',
        () async {
      when(() => capture.isSupported).thenReturn(false);

      expect(await ShouldOfferNotificationCapture(capture, offer)(), isFalse);
      verifyNever(offer.hasBeenOffered);
    });

    test('stays quiet when the system could not be asked', () async {
      when(() => capture.isSupported).thenReturn(true);
      when(offer.hasBeenOffered).thenAnswer((_) async => const Right(false));
      when(capture.isPermissionGranted)
          .thenAnswer((_) async => const Left(UnexpectedFailure('no channel')));

      expect(await ShouldOfferNotificationCapture(capture, offer)(), isFalse);
    });
  });

  group('MarkNotificationCaptureOffered', () {
    test('latches the offer as made', () async {
      when(offer.markOffered).thenAnswer((_) async => const Right(unit));

      await MarkNotificationCaptureOffered(offer)();

      verify(offer.markOffered).called(1);
    });
  });
}
