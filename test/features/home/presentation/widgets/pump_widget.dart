import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a widget with the app's real theme and localizations — same helper
/// as Accounts'/Categorías', so tokens and strings match what actually ships.
///
/// The `wrapInScaffold` flag is on by default (most widgets need a `Material`
/// ancestor);
/// pages that bring their own `Scaffold` (e.g. `MorePage`, `ComingSoonPage`)
/// pass `false`.
extension PumpHome on WidgetTester {
  Future<void> pumpHomeWidget(
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
