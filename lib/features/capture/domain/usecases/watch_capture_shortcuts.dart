import 'package:injectable/injectable.dart';

import '../entities/capture_shortcut.dart';
import '../repositories/capture_shortcut_repository.dart';

/// Shortcuts tapped on the home-screen widget while the app is already
/// running (warm start).
@injectable
class WatchCaptureShortcuts {
  const WatchCaptureShortcuts(this._repository);

  final CaptureShortcutRepository _repository;

  Stream<CaptureShortcut> call() => _repository.shortcuts();
}
