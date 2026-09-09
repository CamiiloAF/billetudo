import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/capture_shortcut.dart';
import '../../domain/repositories/capture_shortcut_repository.dart';
import '../datasources/capture_shortcut_channel_datasource.dart';

/// Platform-channel implementation of [CaptureShortcutRepository]: turns the
/// raw ids the native widgets send into [CaptureShortcut] values and drops
/// anything this build does not recognise.
@LazySingleton(as: CaptureShortcutRepository)
class CaptureShortcutRepositoryImpl implements CaptureShortcutRepository {
  const CaptureShortcutRepositoryImpl(this._datasource);

  final CaptureShortcutChannelDatasource _datasource;

  @override
  FutureResult<CaptureShortcut?> initialShortcut() async {
    try {
      final id = await _datasource.initialShortcutId();
      return Right(id == null ? null : CaptureShortcut.fromId(id));
    } catch (e, st) {
      // A missing channel (a platform without the widget, a widget tap the
      // host could not describe) must never surface as an error to the user:
      // the app just opens where it always does.
      return Left(
        UnexpectedFailure(
          'failed to read the launching capture shortcut',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Stream<CaptureShortcut> shortcuts() => _datasource.shortcutIds
      .map(CaptureShortcut.fromId)
      .where((shortcut) => shortcut != null)
      .cast<CaptureShortcut>();
}
