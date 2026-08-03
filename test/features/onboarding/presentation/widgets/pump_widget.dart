import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a widget with the app's real theme and localizations — same helper
/// as Accounts'/Auth's, so tokens and strings match what actually ships.
///
/// Every onboarding page already brings its own `Scaffold`
/// (`OnboardingScaffold`), so `wrapInScaffold` defaults to `false` here,
/// opposite of the accounts/categories helpers.
extension PumpOnboarding on WidgetTester {
  Future<void> pumpOnboardingWidget(
    Widget child, {
    Locale locale = const Locale('es'),
    bool wrapInScaffold = false,
  }) async {
    await pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: wrapInScaffold ? Scaffold(body: child) : child,
      ),
    );
  }
}
