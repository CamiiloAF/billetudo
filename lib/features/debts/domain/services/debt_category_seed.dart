import '../entities/debt.dart';

/// The single source of truth for the debt-related seed category a movement
/// auto-categorizes into, by [DebtDirection] (fix 7).
///
/// Both the opening movement (`CreateDebtWithOpeningMovement`, via
/// `DebtRepositoryImpl`) and the registrar-abono sheet (`DebtPaymentCubit`)
/// must agree on the same bucket for the same direction — before fix 7 this
/// mapping lived private inside `DebtRepositoryImpl` and the abono sheet had
/// no default at all, so a user paying off a debt could save the movement
/// with no category (or a mismatched one from the opening movement).
///
/// `iOwe` (a debt the user took on) lands in the "Pago de préstamos" bucket;
/// `owedToMe` (a loan the user gave) lands in "Cobro de préstamos" — same
/// `category_seeds` catalog `AdjustAccountBalance` reuses for its own
/// auto-assigned "Otros" categories, so the movement always shows up under a
/// real, debt-labeled category instead of "Sin categoría".
class DebtCategorySeed {
  const DebtCategorySeed._();

  static const String iOweCategoryId = 'seed-debts';
  static const String owedToMeCategoryId = 'seed-loan-collections';

  /// The seed category id a movement of [direction] auto-categorizes into.
  static String categoryIdFor(DebtDirection direction) => switch (direction) {
        DebtDirection.iOwe => iOweCategoryId,
        DebtDirection.owedToMe => owedToMeCategoryId,
      };
}
