import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n/gen/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget of billetudo: light/dark theme (following the system), l10n
/// (follows the device locale, resolving against the supported locales — es +
/// en, with es as the natural fallback) and go_router navigation.
class BilletudoApp extends StatefulWidget {
  const BilletudoApp({super.key});

  @override
  State<BilletudoApp> createState() => _BilletudoAppState();
}

class _BilletudoAppState extends State<BilletudoApp> {
  // Built once, not on every rebuild.
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
