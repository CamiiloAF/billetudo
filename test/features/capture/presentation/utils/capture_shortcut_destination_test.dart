import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/features/capture/domain/entities/capture_shortcut.dart';
import 'package:billetudo/features/capture/presentation/utils/capture_shortcut_destination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaptureShortcutDestination.routeFor', () {
    test('expense opens the movement form with type=expense preselected', () {
      expect(
        CaptureShortcutDestination.routeFor(CaptureShortcut.expense),
        '/movimientos/nuevo?type=expense',
      );
    });

    test('income opens the movement form with type=income preselected', () {
      expect(
        CaptureShortcutDestination.routeFor(CaptureShortcut.income),
        '/movimientos/nuevo?type=income',
      );
    });

    test('bankInbox opens the Avisos centre now that it is wired', () {
      expect(
        CaptureShortcutDestination.routeFor(CaptureShortcut.bankInbox),
        AppRoutes.notices,
      );
    });

    test('voice resolves to Home, not a page route', () {
      // Voice has no `GoRoute` of its own — its surface is a bottom sheet
      // (`VoiceCaptureSheet`) that `CaptureShortcutListener` opens directly
      // over Home, so `routeFor` names Home as the screen it must show over.
      // `CaptureShortcutListener` never actually calls `resolve` for voice
      // (see `capture_shortcut_destination.dart`'s class doc).
      expect(
        CaptureShortcutDestination.routeFor(CaptureShortcut.voice),
        AppRoutes.home,
      );
    });
  });

  group('CaptureShortcutDestination.resolve', () {
    test('navigates when the app is somewhere else', () {
      expect(
        CaptureShortcutDestination.resolve(
          shortcut: CaptureShortcut.expense,
          currentLocation: AppRoutes.home,
        ),
        '/movimientos/nuevo?type=expense',
      );
    });

    test('does nothing when that very form is already open', () {
      // HU-01: a half-filled form is never discarded without asking.
      expect(
        CaptureShortcutDestination.resolve(
          shortcut: CaptureShortcut.expense,
          currentLocation: '/movimientos/nuevo?type=expense',
        ),
        isNull,
      );
    });

    test('pushes on top when a different form is open', () {
      // Pushing (not replacing) keeps whatever was typed underneath.
      expect(
        CaptureShortcutDestination.resolve(
          shortcut: CaptureShortcut.income,
          currentLocation: '/movimientos/nuevo?type=expense',
        ),
        '/movimientos/nuevo?type=income',
      );
    });

    test('does not interrupt the welcome flow', () {
      expect(
        CaptureShortcutDestination.resolve(
          shortcut: CaptureShortcut.expense,
          currentLocation: AppRoutes.onboardingAccount,
        ),
        isNull,
      );
    });
  });

  group('CaptureShortcut.fromId', () {
    test('maps the ids the native widgets send', () {
      expect(CaptureShortcut.fromId('expense'), CaptureShortcut.expense);
      expect(CaptureShortcut.fromId('income'), CaptureShortcut.income);
      expect(CaptureShortcut.fromId('voice'), CaptureShortcut.voice);
      expect(CaptureShortcut.fromId('bank_inbox'), CaptureShortcut.bankInbox);
    });

    test('ignores an id this build does not know', () {
      expect(CaptureShortcut.fromId('receipt_photo'), isNull);
    });
  });
}
