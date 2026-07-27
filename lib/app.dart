import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_cubit.dart';

/// Root widget of billetudo: theme (light/dark, `themeMode` driven by
/// [ThemeModeCubit] — Ajustes → "Apariencia", local-only per-device
/// preference), l10n (follows the device locale, resolving against the
/// supported locales — es + en, with es as the natural fallback) and
/// go_router navigation.
class BilletudoApp extends StatefulWidget {
  const BilletudoApp({super.key});

  @override
  State<BilletudoApp> createState() => _BilletudoAppState();
}

class _BilletudoAppState extends State<BilletudoApp> {
  // Built once, not on every rebuild.
  late final GoRouter _router = createAppRouter();

  // A DI singleton (survives the whole process, not just this widget), so
  // `.value` below — not `create:` — keeps `BlocProvider` from disposing it
  // on a `BilletudoApp` rebuild.
  final ThemeModeCubit _themeModeCubit = getIt<ThemeModeCubit>()..load();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeModeCubit>.value(
      value: _themeModeCubit,
      child: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          routerConfig: _router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }
}
