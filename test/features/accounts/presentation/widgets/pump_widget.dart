import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a widget with the app's real theme and localizations.
///
/// Using the real ones matters: the widgets read `AppColors` off the theme
/// extension and every string off `AppLocalizations`, so a stub would test a
/// different app than the one that ships.
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
