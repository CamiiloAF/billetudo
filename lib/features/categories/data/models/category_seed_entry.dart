import '../../../../core/database/app_database.dart' as db;

/// One row of the `category_seeds` catalog (Supabase, read-only), mapped from
/// Postgres — not a domain nor a presentation type, purely internal to
/// `data/`. See `docs/requirements/05-auth-sync.md`, decision #12: the
/// catalog lives in Postgres now, not in a static Dart list.
///
/// [id] is the catalog's own stable id (e.g. `seed-food-drink`) — reused 1:1
/// as the local `Categories.id` when seeding, which is the whole point of the
/// decision (lets HU-04's merge detect "this account already seeded this
/// category" by primary key).
class CategorySeedEntry {
  const CategorySeedEntry({
    required this.id,
    required this.kind,
    required this.parentId,
    required this.nameEs,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.sortOrder,
  });

  final String id;
  final db.CategoryKind kind;
  final String? parentId;
  final String nameEs;
  final String nameEn;
  final String? icon;
  final String? color;
  final int sortOrder;

  bool get isRoot => parentId == null;

  /// Picks the catalog name for [languageCode], falling back to Spanish for
  /// any language the catalog doesn't carry a translation for (today only
  /// `es`/`en` exist, matching `AppLocalizations.supportedLocales`).
  String nameFor(String languageCode) =>
      languageCode == 'en' ? nameEn : nameEs;
}
