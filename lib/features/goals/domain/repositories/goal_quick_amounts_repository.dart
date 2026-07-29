import '../../../../core/error/result.dart';
import '../entities/goal_quick_amount.dart';

/// Contract for the user-defined "aporte rápido" chips of a goal
/// (design-system/billetudo/pages/metas.md § Aporte rápido). Implemented in
/// `data/` over Drift.
///
/// Removing a chip is a real `DELETE` — same as `Tags`/`TransactionTags` —
/// there is no persistent papelera for this feature. The "Deshacer" snackbar
/// (HU spec) is a UI-timing affordance built on top of [createQuickAmount],
/// not a soft-delete flow.
abstract class GoalQuickAmountsRepository {
  /// Reactive list of chips for [goalId], oldest first — the two defaults
  /// seeded on goal creation come first, then any chips the user adds via
  /// "+ Nueva" append at the end of the scroll row.
  Stream<Result<List<GoalQuickAmount>>> watchQuickAmounts(String goalId);

  /// Creates a new chip: the two defaults seeded right after a goal is
  /// created, the "+ Nueva" sheet's own CTA, or the "Deshacer" re-insertion
  /// after a delete.
  FutureResult<GoalQuickAmount> createQuickAmount({
    required String goalId,
    required int amountMinor,
  });

  /// Deletes a chip. A real `DELETE`, not the reversible `deletedAt` trash —
  /// see the class doc.
  FutureResult<Unit> deleteQuickAmount(String id);
}
