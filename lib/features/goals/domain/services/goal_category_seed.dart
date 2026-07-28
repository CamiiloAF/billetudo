/// The single source of truth for the "Ahorros" seed category id, the
/// default category preselected for a budget-counting aporte (HU-03).
///
/// Mirrors `DebtCategorySeed`: this domain only exposes the stable id the
/// `category_seeds` catalog is expected to carry (kind `expense`); the
/// catalog row itself lives in Supabase (`02-categorias.md`), out of this
/// app's reach.
class GoalCategorySeed {
  const GoalCategorySeed._();

  static const String savingsCategoryId = 'seed-savings';
}
