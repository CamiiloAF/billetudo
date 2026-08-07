import '../../../../core/error/result.dart';
import '../entities/tutorial_key.dart';

/// Contract for the contextual-help minitutorials' "already seen" registry
/// and the account-level on/off preference
/// (`docs/requirements/16-minitutoriales.md`). Implemented in `data/` over
/// Drift's `TutorialViews` table and the `AppSettings.showHelpOnSectionEntry`
/// column.
///
/// "Seen" is per-user and synced (a row per tutorial key seen, never a
/// boolean column per tutorial in `AppSettings`) — see `TutorialViews`'
/// class doc for why the Postgres primary key must be composite.
abstract class TutorialsRepository {
  /// Whether [key] has already been dismissed (either via its CTA,
  /// "Entendido", or the sheet's standard close gesture — all count as
  /// seen). `false` also covers the "row is for a retired key" case, which
  /// never happens for a live [TutorialKey] but keeps the contract total.
  FutureResult<bool> hasSeen(TutorialKey key);

  /// Marks [key] as seen. Idempotent: calling it again for an
  /// already-seen key is a no-op success, not an error.
  FutureResult<Unit> markSeen(TutorialKey key);

  /// Clears every row in the "already seen" registry — every tutorial shows
  /// again once. Only ever called by `SetTutorialsEnabled` when the account
  /// toggles the help preference back on (HU-04).
  FutureResult<Unit> resetAll();

  /// Observes `AppSettings.showHelpOnSectionEntry` (HU-04): whether a
  /// tutorial the user hasn't seen yet is allowed to appear unprompted.
  /// Reopening from a screen's "Ver ayuda"/`?` action always works
  /// regardless of this value.
  Stream<Result<bool>> watchHelpEnabled();

  /// Sets `AppSettings.showHelpOnSectionEntry`. Does NOT reset the "seen"
  /// registry itself — that side effect is `SetTutorialsEnabled`'s
  /// responsibility (domain-level business rule), not the repository's.
  FutureResult<Unit> setHelpEnabled({required bool enabled});
}
