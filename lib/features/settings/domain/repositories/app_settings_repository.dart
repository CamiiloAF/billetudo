import '../../../../core/error/result.dart';
import '../../../home/domain/entities/quick_access_item.dart';
import '../entities/app_settings.dart';

/// Contract for reading and writing the account-level [AppSettings] singleton.
/// Implemented in `data/` over the Drift `AppSettings` row (id `'app'`).
///
/// Writes are an upsert on that constant id — never a second row — and stamp
/// `updatedAt` so PowerSync merges last-write-wins.
abstract class AppSettingsRepository {
  /// Observes the settings singleton, re-emitting on every change. Emits
  /// [AppSettings.defaults] semantics if the row is somehow missing.
  Stream<Result<AppSettings>> watchSettings();

  /// One-shot read of the settings singleton (not a stream). Returns
  /// [AppSettings.defaults] semantics if the row is somehow missing.
  FutureResult<AppSettings> getSettings();

  /// Turns "Modo sobres" (zero-based) on or off (HU-06).
  FutureResult<Unit> setZeroBasedEnabled({required bool enabled});

  /// Latches the onboarding default categories as seeded for this installation
  /// (HU-06). Idempotent: safe to call again.
  FutureResult<Unit> markCategoriesSeeded();

  /// Latches the welcome flow as completed for this installation
  /// (`docs/requirements/fase-1/13-onboarding.md`). Idempotent: safe to call again;
  /// the flag never turns off.
  FutureResult<Unit> markOnboardingCompleted();

  /// Manually picks the budget featured on the Home hero card
  /// (`design-system/billetudo/pages/ajustes.md`, "Presupuesto destacado").
  /// Sets `AppSettings.featuredBudgetMode` to `manual` alongside the id.
  FutureResult<Unit> setFeaturedBudget({required String budgetId});

  /// Clears the featured budget: `AppSettings.featuredBudgetMode` goes to
  /// `none` (the user explicitly wants no featured budget, and no automatic
  /// fallback) and `featuredBudgetId` is reset to `null`.
  FutureResult<Unit> clearFeaturedBudget();

  /// Persists the Home quick-access chips' order (`QuickAccessRow`).
  ///
  /// [order] must already be a valid permutation of
  /// [QuickAccessItem.values] — validating that is `SetQuickAccessOrder`'s
  /// job (domain business rule), not this method's; this is a plain write.
  FutureResult<Unit> setQuickAccessOrder(List<QuickAccessItem> order);

  /// Records the AI assistant's third-party data-sharing consent (Apple
  /// 5.1.2(i)) as accepted now, stamping `currentAiConsentVersion` alongside
  /// the timestamp in the same write. Idempotent: calling it again just moves
  /// the timestamp forward, which is harmless since the gate checks presence
  /// plus version, never the exact instant.
  FutureResult<Unit> markAiConsentAccepted();

  /// Withdraws that same consent (RGPD art. 7.3 — withdrawing has to be as
  /// easy as granting): `aiConsentAcceptedAt` and `aiConsentVersion` go back
  /// to `null`, and [AppSettings.aiNotesAccessEnabled] is forced off in the
  /// same write, because the notes opt-in only exists inside the broad
  /// consent and would otherwise survive as a permission the person believes
  /// they cancelled. Idempotent: withdrawing twice is a harmless re-write.
  FutureResult<Unit> clearAiConsent();

  /// Turns the assistant's access to the records' free-text `note` on or off
  /// ([AppSettings.aiNotesAccessEnabled]). Off by default; nothing reads a
  /// note anywhere until this is explicitly `true`.
  FutureResult<Unit> setAiNotesAccessEnabled({required bool enabled});
}
