import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'theme_preference_datasource.dart';

/// The app-wide [ThemeMode] (Ajustes → "Apariencia"), backed by
/// [ThemePreferenceDatasource]. Local-only, per-device — unlike
/// `AppSettingsCubit` (account-level, synced via PowerSync), this cubit is
/// registered `@lazySingleton` (built once, on first request — which
/// `BilletudoApp` makes immediately at startup — then reused) so the same
/// instance keeps driving `MaterialApp`'s `themeMode` for the whole process
/// lifetime, not just one page. Not `@singleton` (eager): that would build it
/// — and its `SharedPreferencesAsync` dependency — during
/// `configureDependencies()` itself, before the platform channel it needs is
/// necessarily available (e.g. in unit tests that never touch theming).
@lazySingleton
class ThemeModeCubit extends Cubit<ThemeMode> {
  ThemeModeCubit(this._datasource) : super(ThemeMode.system);

  final ThemePreferenceDatasource _datasource;

  /// Loads the persisted preference. Called once, right after the cubit is
  /// resolved from the DI container (see `BilletudoApp`).
  Future<void> load() async {
    final mode = await _datasource.read();
    if (!isClosed) {
      emit(mode);
    }
  }

  /// Applies [mode] immediately and persists it — no confirmation step, per
  /// the approved design (`design-system/billetudo/pages/ajustes.md`).
  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    await _datasource.write(mode);
  }
}
