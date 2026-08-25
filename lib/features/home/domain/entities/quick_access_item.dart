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
/// Cuentas is deliberately not a member: `QuickAccessRow` never included it
/// (the "Mis cuentas" strip right below Home's hero card already covers that
/// shortcut), so there is nothing to reorder for it.
enum QuickAccessItem {
  scheduledPayments,
  debts,
  reports;

  /// Today's fixed order, kept as the default for every installation that
  /// predates the reorder feature and as the fallback whenever the persisted
  /// value is missing or malformed (see
  /// `AppSettingsRepositoryImpl._toQuickAccessOrder`).
  static const List<QuickAccessItem> defaultOrder = [
    QuickAccessItem.scheduledPayments,
    QuickAccessItem.debts,
    QuickAccessItem.reports,
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
