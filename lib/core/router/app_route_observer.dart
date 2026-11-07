import 'package:flutter/widgets.dart';

/// A [NavigatorObserver] that only counts navigation changes.
///
/// It exists for surfaces that must act **only while the user is actually
/// looking at them**, and that would otherwise act late (or over another
/// screen): `TutorialAutoShow` evaluates its gate asynchronously after a screen
/// mounts, and a screen can be covered before that evaluation resolves — the
/// exact wrong-tutorial bug seen when finishing onboarding lands on Inicio and
/// immediately pushes the new-account form on top of it.
///
/// The counter is deliberately not a `RouteObserver` with route matching: the
/// interesting routes live in different navigators (`StatefulShellRoute`
/// branches vs. the root navigator), and a widget cannot easily subscribe to
/// the *outer* route that covers its branch. "Some navigation happened, so my
/// visibility may have changed; re-check it" is all the tutorial gate needs.
///
/// Registered on the app's router (`createAppRouter`'s `GoRouter.observers`).
class AppRouteObserver extends NavigatorObserver {
  AppRouteObserver();

  /// Increments on every push, pop, replace and remove. Listeners must not
  /// mutate the tree synchronously from here (navigators are mid-transition);
  /// schedule work with `addPostFrameCallback` like the tutorials do.
  final ValueNotifier<int> navigationChanges = ValueNotifier<int>(0);

  void _notify() => navigationChanges.value++;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _notify();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _notify();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _notify();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _notify();
  }
}

/// The app-wide instance. One per process is enough: it is a change signal, not
/// a registry of routes.
final AppRouteObserver appRouteObserver = AppRouteObserver();
