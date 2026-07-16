import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a widget with the app's real theme and localizations — same helper
/// as Accounts', so tokens/strings match what actually ships.
extension PumpApp on WidgetTester {
  Future<void> pumpAppWidget(
    Widget child, {
    Locale locale = const Locale('es'),
  }) async {
    await pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }
}
