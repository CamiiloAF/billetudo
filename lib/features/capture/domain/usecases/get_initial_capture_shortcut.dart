import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/capture_shortcut.dart';
import '../repositories/capture_shortcut_repository.dart';

/// The shortcut that launched the app from the home-screen widget, read once
/// per process start (HU-01: cold start must work, and its only cost is a
/// slower launch — never an error).
@injectable
class GetInitialCaptureShortcut {
  const GetInitialCaptureShortcut(this._repository);

  final CaptureShortcutRepository _repository;

  FutureResult<CaptureShortcut?> call() => _repository.initialShortcut();
}
