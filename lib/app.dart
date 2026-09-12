import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_cubit.dart';
import 'features/capture/presentation/cubit/capture_shortcut_cubit.dart';
import 'features/capture/presentation/widgets/capture_shortcut_listener.dart';

/// Root widget of billetudo: theme (light/dark, `themeMode` driven by
/// [ThemeModeCubit] — Ajustes → "Apariencia", local-only per-device
/// preference), l10n (follows the device locale, resolving against the
/// supported locales — es + en, with es as the natural fallback) and
/// go_router navigation.
class BilletudoApp extends StatefulWidget {
  const BilletudoApp({this.initialLocation = AppRoutes.home, super.key});

  /// `bootstrap.dart` resolves this once, before the widget tree exists, via
  /// `ShouldShowOnboarding` (`13-onboarding.md`, "El gate se evalúa una sola
  /// vez por arranque, tras el bootstrap") — [AppRoutes.onboarding] when the
  /// welcome flow has not run yet, [AppRoutes.home] otherwise. Not a
  /// `redirect`: a one-shot decision, so a remote change to the latch
  /// arriving mid-session never yanks the user off the screen they are on.
  final String initialLocation;

  @override
  State<BilletudoApp> createState() => _BilletudoAppState();
}

class _BilletudoAppState extends State<BilletudoApp> {
  // Built once, not on every rebuild.
  late final GoRouter _router =
      createAppRouter(initialLocation: widget.initialLocation);

  // A DI singleton (survives the whole process, not just this widget), so
  // `.value` below — not `create:` — keeps `BlocProvider` from disposing it
  // on a `BilletudoApp` rebuild.
  final ThemeModeCubit _themeModeCubit = getIt<ThemeModeCubit>()..load();

  // Also a DI singleton: a home-screen widget tap can arrive before the first
  // frame (cold start) or while the app sits in the background, and both go
  // through this same instance
  // (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
  late final CaptureShortcutCubit _captureShortcutCubit =
      getIt<CaptureShortcutCubit>()..start();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeModeCubit>.value(value: _themeModeCubit),
        BlocProvider<CaptureShortcutCubit>.value(value: _captureShortcutCubit),
      ],
      child: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          routerConfig: _router,
          // Wraps the router's own subtree, so the shortcut can navigate no
          // matter which screen is on top.
          builder: (context, child) => CaptureShortcutListener(
            currentLocation: () =>
                _router.routerDelegate.currentConfiguration.uri.toString(),
            onOpenRoute: (route) => unawaited(_router.push<Object?>(route)),
            child: child ?? const SizedBox.shrink(),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }
}
