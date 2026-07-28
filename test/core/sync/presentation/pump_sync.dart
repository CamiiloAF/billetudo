import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a `core/sync` widget with the app's real theme and localizations —
/// same shape as the per-feature helpers (`test/features/home/.../
/// pump_widget.dart`), so tokens and strings match what actually ships.
///
/// Pages that bring their own `Scaffold` (`SyncStatusPage`,
/// `PendingSyncChangesPage`) pass `wrapInScaffold: false`.
extension PumpSync on WidgetTester {
  Future<void> pumpSyncWidget(
    Widget child, {
    Locale locale = const Locale('es'),
    Brightness brightness = Brightness.light,
    bool wrapInScaffold = true,
  }) async {
    await pumpWidget(
      MaterialApp(
        theme:
            brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: wrapInScaffold ? Scaffold(body: child) : child,
      ),
    );
  }
}
