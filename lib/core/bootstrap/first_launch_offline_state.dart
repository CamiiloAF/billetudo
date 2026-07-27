import 'package:equatable/equatable.dart';

/// Status of the retry attempt on the "Primer arranque — sin conexión"
/// screen (`KSkpO`/`zeAfp`).
enum FirstLaunchOfflineStatus {
  /// Nothing in flight — either the initial state, or a retry that failed
  /// and can be attempted again. Deliberately not a separate `error` status:
  /// the screen's copy never blames the user (CLAUDE.md tone rule), it just
  /// lets them tap "Reintentar" again.
  idle,

  /// The retry is calling `SeedDefaultCategories` again.
  retrying,

  /// The retry succeeded — the gate (`FirstLaunchOfflineGate`) reacts to this
  /// by swapping in the real app.
  success,
}

/// State of `FirstLaunchOfflineCubit`.
class FirstLaunchOfflineState extends Equatable {
  const FirstLaunchOfflineState({
    this.status = FirstLaunchOfflineStatus.idle,
  });

  final FirstLaunchOfflineStatus status;

  FirstLaunchOfflineState copyWith({FirstLaunchOfflineStatus? status}) =>
      FirstLaunchOfflineState(status: status ?? this.status);

  @override
  List<Object?> get props => [status];
}
