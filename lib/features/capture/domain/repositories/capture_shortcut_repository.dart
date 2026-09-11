import '../../../../core/error/result.dart';
import '../entities/capture_shortcut.dart';

/// Source of the shortcuts fired from the home-screen widget
/// (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
///
/// Two moments, because the platforms deliver the tap in two different
/// situations: the app was not running (cold start, HU-01 "funciona con el
/// teléfono recién encendido") and the app was already alive in the
/// background.
abstract class CaptureShortcutRepository {
  /// The shortcut the app was launched with, if any. `Right(null)` means the
  /// app was opened the normal way (launcher icon).
  FutureResult<CaptureShortcut?> initialShortcut();

  /// Shortcuts arriving while the app is already running.
  Stream<CaptureShortcut> shortcuts();
}
