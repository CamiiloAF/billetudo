import 'package:flutter/material.dart';

/// The app's snackbar: always auto-dismisses.
///
/// Material's [SnackBar] defaults `persist` to `action != null`, so *any*
/// snackbar carrying a [SnackBarAction] stays on screen forever until the
/// action is tapped. That turned "No se pudo subir todo" (HU-08) into a banner
/// that never went away, and the same default silently applied to every
/// "Deshacer" in the app.
///
/// Undo and "ver todo" are offers, not blockers: they expire with the
/// snackbar. Use this class instead of [SnackBar] everywhere so the default
/// cannot come back — pass `persist: true` only for a snackbar that genuinely
/// must be acknowledged.
class AppSnackBar extends SnackBar {
  AppSnackBar({
    required super.content,
    super.action,
    super.duration,
    super.persist = false,
    super.behavior,
    super.backgroundColor,
    super.showCloseIcon,
    super.margin,
    super.key,
  });
}
