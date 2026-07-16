import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a widget with the app's real theme and localizations — same helper
/// as Accounts'/Categorías'/Home's, so tokens and strings match what
/// actually ships.
///
/// `wrapInScaffold` is on by default for sheet content (which relies on an
/// ambient `Material`); full pages (`LoginPage`, `MergeConfirmationPage`,
/// `AccountDeletedPage`) already bring their own `Scaffold` and pass `false`.
extension PumpAuth on WidgetTester {
  Future<void> pumpAuthWidget(
    Widget child, {
    Locale locale = const Locale('es'),
    bool wrapInScaffold = true,
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
