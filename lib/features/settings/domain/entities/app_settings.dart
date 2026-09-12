import 'package:equatable/equatable.dart';

import '../../../ai/domain/entities/ai_consent.dart';
import '../../../home/domain/entities/quick_access_item.dart';

/// How [AppSettings.featuredBudgetId] is resolved for the Home hero card
/// (`design-system/billetudo/pages/ajustes.md`, "Presupuesto destacado").
/// Mirrors the Drift `FeaturedBudgetMode` enum (`app_database.dart`) as text
/// parity with Postgres — this is the pure domain copy, the same convention
/// `AccountType` (`accounts/domain/entities/account.dart`) already follows so
/// `domain/` never depends on Drift.
///
///  - `automatic` (default): the pre-existing fallback — the single active
///    budget, if any, that is both global and monthly (`BudgetHeroSelector`).
///  - `manual`: [AppSettings.featuredBudgetId] picks the budget (falling back
///    to `automatic` if it is no longer active/valid).
///  - `none`: the user explicitly wants no featured budget on Home, with no
///    automatic fallback either.
enum FeaturedBudgetMode { automatic, manual, none }

/// Account-level app preferences that sync across devices (a single row in
/// Drift's `AppSettings`, id `'app'`).
///
/// Pure domain entity: it never carries the Drift row type. Today it holds the
/// "Modo sobres" (zero-based) flag (HU-06); more synced preferences (default
/// currency) will land here.
class AppSettings extends Equatable {
  const AppSettings({
    required this.zeroBasedEnabled,
    required this.categoriesSeeded,
    required this.onboardingCompleted,
    this.featuredBudgetId,
    this.featuredBudgetMode = FeaturedBudgetMode.automatic,
    this.quickAccessOrder = QuickAccessItem.defaultOrder,
    this.aiConsentAcceptedAt,
    this.aiConsentVersion = 0,
    this.aiNotesAccessEnabled = false,
    this.legalAcceptedAt,
    this.legalAcceptedVersion = 0,
  });

  /// Sensible default before the singleton row has been read.
  const AppSettings.defaults()
      : zeroBasedEnabled = false,
        categoriesSeeded = false,
        onboardingCompleted = false,
        featuredBudgetId = null,
        featuredBudgetMode = FeaturedBudgetMode.automatic,
        quickAccessOrder = QuickAccessItem.defaultOrder,
        aiConsentAcceptedAt = null,
        aiConsentVersion = 0,
        aiNotesAccessEnabled = false,
        legalAcceptedAt = null,
        legalAcceptedVersion = 0;

  /// Whether "Modo sobres" (zero-based budgeting) is on (HU-06).
  final bool zeroBasedEnabled;

  /// Whether the onboarding default categories have already been seeded for
  /// this installation (HU-06). Once true, never seeded again — even if the
  /// user deletes every category.
  final bool categoriesSeeded;

  /// One-shot latch for the welcome flow (`docs/requirements/fase-1/13-onboarding.md`).
  /// Turns on once the user reaches the closing screen and acts on it (or logs
  /// in via "Ya tengo cuenta"), or silently if the installation already had an
  /// active account when first evaluated. Never turns off again.
  final bool onboardingCompleted;

  /// Manually picked budget to feature on the Home hero card
  /// (`design-system/billetudo/pages/ajustes.md`, "Presupuesto destacado").
  /// Null (the default) falls back to the automatic global+monthly selection
  /// in `BudgetHeroSelector`. Loosely references `Budgets.id` — an
  /// archived/deleted budget simply stops matching in the selector.
  final String? featuredBudgetId;

  /// Explicit resolution mode for [featuredBudgetId] — see [FeaturedBudgetMode].
  final FeaturedBudgetMode featuredBudgetMode;

  /// Persisted order of the Home quick-access chips (`QuickAccessRow`).
  /// Always a valid permutation of [QuickAccessItem.values] — never partial,
  /// never duplicated — because `AppSettingsRepositoryImpl` (`data/`) falls
  /// back to [QuickAccessItem.defaultOrder] before this entity is built
  /// whenever the stored value is missing or malformed. Defaults to
  /// [QuickAccessItem.defaultOrder], today's fixed order.
  final List<QuickAccessItem> quickAccessOrder;

  /// When the user consented to the AI assistant sending their message and a
  /// snapshot of their finances to a third-party model (Apple 5.1.2(i);
  /// privacy policy §17). `null` = not asked yet, or asked and not yet
  /// accepted — the assistant's composer stays gated until this is set.
  final DateTime? aiConsentAcceptedAt;

  /// Which version of the consent copy was accepted
  /// (`AppSettings.aiConsentVersion`). `0` means "accepted before the column
  /// existed, or never accepted" — the Drift column is nullable and is read as
  /// `0` in `data/` rather than backfilled.
  final int aiConsentVersion;

  /// Whether the user explicitly let the assistant read the free-text `note`
  /// of their records. **Off by default**: with this `false` — the state of
  /// anyone who has done nothing — not a single note travels in any payload,
  /// which is the behavior every version before this opt-in had.
  final bool aiNotesAccessEnabled;

  /// When the person last accepted the legal terms (privacy policy + terms
  /// of use) — one joint timestamp, alongside [legalAcceptedVersion]'s
  /// "which version". `null` = not accepted yet on this installation.
  final DateTime? legalAcceptedAt;

  /// Which joint legal-package version was accepted, alongside
  /// [legalAcceptedAt]. `0` means "accepted before the column existed, or
  /// never accepted" — the Drift column is nullable and is read as `0` in
  /// `data/` rather than backfilled, same convention as [aiConsentVersion].
  final int legalAcceptedVersion;

  /// Consent counts as granted only when it was given AND given against copy
  /// at least as current as this build's ([currentAiConsentVersion]). A lower
  /// stored version re-shows the consent screen even though the timestamp is
  /// set: the person consented to a narrower disclosure than what the app now
  /// does (Apple 5.1.2(i) — consent has to be informed).
  bool get hasAcceptedAiConsent =>
      aiConsentAcceptedAt != null &&
      aiConsentVersion >= currentAiConsentVersion;

  AppSettings copyWith({
    bool? zeroBasedEnabled,
    bool? categoriesSeeded,
    bool? onboardingCompleted,
    String? featuredBudgetId,
    FeaturedBudgetMode? featuredBudgetMode,
    List<QuickAccessItem>? quickAccessOrder,
    DateTime? aiConsentAcceptedAt,
    int? aiConsentVersion,
    bool? aiNotesAccessEnabled,
    DateTime? legalAcceptedAt,
    int? legalAcceptedVersion,
  }) =>
      AppSettings(
        zeroBasedEnabled: zeroBasedEnabled ?? this.zeroBasedEnabled,
        categoriesSeeded: categoriesSeeded ?? this.categoriesSeeded,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        featuredBudgetId: featuredBudgetId ?? this.featuredBudgetId,
        featuredBudgetMode: featuredBudgetMode ?? this.featuredBudgetMode,
        quickAccessOrder: quickAccessOrder ?? this.quickAccessOrder,
        aiConsentAcceptedAt: aiConsentAcceptedAt ?? this.aiConsentAcceptedAt,
        aiConsentVersion: aiConsentVersion ?? this.aiConsentVersion,
        aiNotesAccessEnabled: aiNotesAccessEnabled ?? this.aiNotesAccessEnabled,
        legalAcceptedAt: legalAcceptedAt ?? this.legalAcceptedAt,
        legalAcceptedVersion: legalAcceptedVersion ?? this.legalAcceptedVersion,
      );

  @override
  List<Object?> get props => [
        zeroBasedEnabled,
        categoriesSeeded,
        onboardingCompleted,
        featuredBudgetId,
        featuredBudgetMode,
        quickAccessOrder,
        aiConsentAcceptedAt,
        aiConsentVersion,
        aiNotesAccessEnabled,
        legalAcceptedAt,
        legalAcceptedVersion,
      ];
}
