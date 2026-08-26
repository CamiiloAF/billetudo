import 'package:equatable/equatable.dart';

/// Whether this user may talk to the assistant, as decided **server-side**.
///
/// The gate is never a client decision: quotas and flags are counted and
/// validated in Supabase (`CLAUDE.md`, "Reglas de negocio"), and the function
/// fails closed when it cannot read them. This entity only carries the verdict
/// so the UI can hide or explain the entry point.
class AiAccess extends Equatable {
  const AiAccess({
    required this.allowed,
    this.reason,
    this.betaLabel,
    this.remainingToday,
    this.features = const <String>{},
  });

  /// Denied access with no explanation at all — the safe default when the
  /// check itself could not run.
  static const AiAccess denied = AiAccess(allowed: false);

  final bool allowed;

  /// Why access was denied, **already localized by the backend**. The reason
  /// space (not enabled yet, quota spent, region) grows faster than app
  /// releases ship, so translating it here would mean a stale generic message
  /// for every reason added after the build.
  final String? reason;

  /// Badge copy for a limited rollout ("Beta"), also backend-localized.
  /// `null` = no badge.
  final String? betaLabel;

  /// Messages still available today. `null` means **not measured**, which is
  /// not the same as `0`: Fase A has no quota, so nothing to count down.
  final int? remainingToday;

  /// Opaque server-side capability flags (e.g. tool names, experiment ids).
  /// Kept as raw strings on purpose: an unknown flag must be ignorable, and an
  /// enum would make every new flag a breaking parse.
  final Set<String> features;

  bool get isBeta => betaLabel != null;

  @override
  List<Object?> get props =>
      [allowed, reason, betaLabel, remainingToday, features];
}
