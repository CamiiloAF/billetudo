import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/app_database.dart' as db;
import '../models/category_seed_entry.dart';

/// Thrown by [CategorySeedsRemoteDatasource.fetchCatalog] when the catalog
/// can't be read — no connectivity on the device's first launch, Supabase
/// unreachable, or a malformed row. Carries [cause] so the repository can
/// attach it to the `NetworkFailure` it maps this to (see `core/error/
/// failure.dart` and `CategoryRepositoryImpl`), instead of this bubbling up
/// as a bare, uncaught exception.
class CategorySeedsFetchException implements Exception {
  const CategorySeedsFetchException(this.cause);

  final Object cause;

  @override
  String toString() => 'CategorySeedsFetchException($cause)';
}

/// Reads the read-only `category_seeds` catalog table (Supabase Postgres) —
/// the canonical source of HU-06's onboarding categories as of
/// `docs/requirements/05-auth-sync.md` decision #12. Public `SELECT` RLS
/// policy (`anon` + `authenticated`): this never requires a signed-in
/// session, since seeding happens before the user ever logs in.
@lazySingleton
class CategorySeedsRemoteDatasource {
  const CategorySeedsRemoteDatasource(this._supabase);

  final SupabaseClient _supabase;

  static const _table = 'category_seeds';

  /// Fetches every row of the catalog, in no particular order (callers sort
  /// as needed — the local datasource seeds roots before subcategories to
  /// satisfy the FK on `Categories.parentId`).
  ///
  /// Throws [CategorySeedsFetchException] on any failure: a
  /// `PostgrestException` from a malformed/rejected query, or anything else
  /// (typically a `SocketException`/`ClientException` when there is no
  /// network at all) — both are folded into the same exception type because
  /// the repository treats them identically (a `NetworkFailure` the app
  /// blocks the first launch on, per HU-06).
  Future<List<CategorySeedEntry>> fetchCatalog() async {
    try {
      final rows = await _supabase.from(_table).select();
      return rows.map(_toEntry).toList();
    } on PostgrestException catch (e) {
      throw CategorySeedsFetchException(e);
    } catch (e) {
      throw CategorySeedsFetchException(e);
    }
  }

  CategorySeedEntry _toEntry(Map<String, dynamic> row) => CategorySeedEntry(
        id: row['id'] as String,
        kind: (row['kind'] as String) == 'income'
            ? db.CategoryKind.income
            : db.CategoryKind.expense,
        parentId: row['parent_id'] as String?,
        nameEs: row['name_es'] as String,
        nameEn: row['name_en'] as String,
        icon: row['icon'] as String?,
        color: row['color'] as String?,
        sortOrder: row['sort_order'] as int,
      );
}
