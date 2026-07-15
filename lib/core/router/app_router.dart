import 'package:go_router/go_router.dart';

import 'bootstrap_home_page.dart';

/// App routes. Each feature registers its own here (Accounts, Categories,
/// Transactions). Paths stay in Spanish because they are user-visible URLs.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String accounts = '/cuentas';
  static const String categories = '/categorias';
  static const String transactions = '/movimientos';
}

/// Builds the app [GoRouter]. Instantiated once during bootstrap.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const BootstrapHomePage(),
      ),
    ],
  );
}
