import 'package:equatable/equatable.dart';

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
  });

  /// Sensible default before the singleton row has been read.
  const AppSettings.defaults()
      : zeroBasedEnabled = false,
        categoriesSeeded = false,
        onboardingCompleted = false,
        featuredBudgetId = null,
        featuredBudgetMode = FeaturedBudgetMode.automatic,
        quickAccessOrder = QuickAccessItem.defaultOrder,
        aiConsentAcceptedAt = null;

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

  bool get hasAcceptedAiConsent => aiConsentAcceptedAt != null;

  AppSettings copyWith({
    bool? zeroBasedEnabled,
    bool? categoriesSeeded,
    bool? onboardingCompleted,
    String? featuredBudgetId,
    FeaturedBudgetMode? featuredBudgetMode,
    List<QuickAccessItem>? quickAccessOrder,
    DateTime? aiConsentAcceptedAt,
  }) =>
      AppSettings(
        zeroBasedEnabled: zeroBasedEnabled ?? this.zeroBasedEnabled,
        categoriesSeeded: categoriesSeeded ?? this.categoriesSeeded,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        featuredBudgetId: featuredBudgetId ?? this.featuredBudgetId,
        featuredBudgetMode: featuredBudgetMode ?? this.featuredBudgetMode,
        quickAccessOrder: quickAccessOrder ?? this.quickAccessOrder,
        aiConsentAcceptedAt: aiConsentAcceptedAt ?? this.aiConsentAcceptedAt,
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
      ];
}
