/// One shortcut chip in Home's quick-access row (`QuickAccessRow`).
///
/// Text-parity enum (mirrors the Drift/Postgres convention every other
/// domain enum in this app follows, e.g. `AccountType` and
/// `FeaturedBudgetMode`): the persisted form
/// (`AppSettings.quickAccessOrder`, `lib/core/database/app_database.dart`) is
/// a comma-separated list of [name] values, never the enum index — indices
/// are not stable across releases if a new item is inserted in the middle,
/// names are.
///
/// `accounts` and `goals` joined the row in the Home hero redesign
/// (`design-system/billetudo/pages/inicio.md`): the "Mis cuentas" strip that
/// used to cover the Cuentas shortcut was removed from Home (its atajo is now
/// the header's wallet button → "Tu dinero" sheet), so Cuentas needed a seat
/// here like every other destination; Metas joined at the same time to round
/// the row out to 5.
///
/// A persisted value with only the original 3 names (from before this change)
/// is not a valid permutation of the now-5-member enum: [isValidOrder]
/// rejects it and `AppSettingsRepositoryImpl` falls back to [defaultOrder] —
/// the documented "malformed" path, not a crash. There is no migration that
/// upgrades an old 3-item order in place; the fallback is the intended
/// backward-compat behavior (criterion: "mantener compatibilidad hacia atrás
/// con datos persistidos de 3 items").
enum QuickAccessItem {
  scheduledPayments,
  debts,
  reports,
  accounts,
  goals;

  /// Today's fixed order, kept as the default for every installation that
  /// predates the reorder feature (or the 3→5 expansion above) and as the
  /// fallback whenever the persisted value is missing or malformed (see
  /// `AppSettingsRepositoryImpl._toQuickAccessOrder`).
  static const List<QuickAccessItem> defaultOrder = [
    QuickAccessItem.scheduledPayments,
    QuickAccessItem.accounts,
    QuickAccessItem.debts,
    QuickAccessItem.reports,
    QuickAccessItem.goals,
  ];

  /// Whether [items] is an exact permutation of [values]: same length, no
  /// duplicates, no unknown members missing. Used both to validate a
  /// candidate order before persisting it (`SetQuickAccessOrder`) and to
  /// decide whether a value read back from storage can be trusted
  /// (`AppSettingsRepositoryImpl`).
  static bool isValidOrder(List<QuickAccessItem> items) =>
      items.length == QuickAccessItem.values.length &&
      items.toSet().length == QuickAccessItem.values.length;
}
