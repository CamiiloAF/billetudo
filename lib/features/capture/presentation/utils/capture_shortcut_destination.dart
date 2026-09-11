import '../../../../core/router/app_router.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/capture_shortcut.dart';

/// Translates a home-screen widget shortcut into the route the app must open
/// (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
///
/// Pure and router-free on purpose: the navigation itself belongs to
/// `CaptureShortcutListener`, so the two rules that are easy to get wrong —
/// the fallback for destinations that do not exist yet, and never discarding
/// a form the user is already filling — are testable without a widget tree.
abstract final class CaptureShortcutDestination {
  const CaptureShortcutDestination._();

  /// Where [shortcut] wants to go, before considering where the app already
  /// is. A destination still on `AppRoutes.pendingWidgetTargets` degrades to
  /// the manual expense form instead of a router error page (HU-01/HU-02).
  static String routeFor(CaptureShortcut shortcut) {
    final route = switch (shortcut) {
      CaptureShortcut.expense =>
        AppRoutes.newTransactionOfType(TransactionType.expense),
      CaptureShortcut.income =>
        AppRoutes.newTransactionOfType(TransactionType.income),
      CaptureShortcut.voice => AppRoutes.voiceCapture,
      CaptureShortcut.bankInbox => AppRoutes.bankInbox,
    };
    return AppRoutes.pendingWidgetTargets.contains(route)
        ? AppRoutes.newTransactionOfType(TransactionType.expense)
        : route;
  }

  /// The route to push for [shortcut] when the app is showing
  /// [currentLocation], or `null` when the tap must change nothing.
  ///
  /// Two cases return `null`, both required by the feature:
  /// - The app is already exactly on that destination. HU-01 forbids
  ///   discarding what the user already typed without asking, and the
  ///   cheapest way to honour that is to let the in-progress form continue.
  ///   (A *different* destination is pushed on top instead of replacing, so
  ///   the half-filled form is still there when the user goes back — nothing
  ///   is discarded there either.)
  /// - The app is in the welcome flow. Dropping a capture form on top of
  ///   onboarding would strand the user mid-setup; the widget still opened
  ///   the app, which is never an error.
  static String? resolve({
    required CaptureShortcut shortcut,
    required String currentLocation,
  }) {
    if (currentLocation.startsWith(AppRoutes.onboarding)) {
      return null;
    }
    final route = routeFor(shortcut);
    return currentLocation == route ? null : route;
  }
}
