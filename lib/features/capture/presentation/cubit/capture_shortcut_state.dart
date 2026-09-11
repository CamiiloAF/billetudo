import 'package:equatable/equatable.dart';

import '../../domain/entities/capture_shortcut.dart';

/// State of `CaptureShortcutCubit`: at most one shortcut waiting to be
/// navigated to.
class CaptureShortcutState extends Equatable {
  const CaptureShortcutState({this.pending});

  /// The shortcut tapped on the home-screen widget that the app has not
  /// navigated to yet. `null` while there is nothing pending.
  final CaptureShortcut? pending;

  @override
  List<Object?> get props => [pending];
}
