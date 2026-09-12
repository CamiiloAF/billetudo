import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/repositories/account_repository.dart';
import '../../../budgets/domain/entities/budget_draft.dart';
import '../../../budgets/domain/usecases/create_budget.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/entities/category_draft.dart';
import '../../../categories/domain/usecases/create_category.dart';
import '../../../categories/domain/usecases/get_category.dart';
import '../../../debts/domain/entities/debt.dart';
import '../../../debts/domain/repositories/debt_repository.dart';
import '../../../debts/domain/services/debt_event_rules.dart';
import '../../../debts/domain/usecases/link_transaction_to_debt.dart';
import '../../../goals/domain/entities/goal_draft.dart';
import '../../../goals/domain/usecases/create_goal.dart';
import '../../../transactions/domain/entities/transaction.dart'
    show TransactionSource;
import '../../../transactions/domain/entities/transaction_draft.dart';
import '../../../transactions/domain/usecases/create_transaction.dart';
import '../entities/ai_action_outcome.dart';
import '../entities/ai_action_proposal.dart';

/// Executes a proposal the user tapped to confirm.
///
/// This is the **only** place a suggestion becomes a row. Nothing upstream
/// writes: the backend never runs a write tool, and the mapper never executes
/// one either.
///
/// What this use case does *not* do is re-validate. `BudgetDraft.validated`,
/// `GoalDraft.validated`, `CategoryDraft.validated` and
/// `TransactionDraft.validated` already enforce the name, the positive amount,
/// the ISO currency and the category-kind coherence, and each `Create*` use
/// case already enforces its own referential rules (a goal's account must
/// exist, a subcategory's parent must be a root). Duplicating any of that here
/// would create a second, divergent copy of the rule.
///
/// What is left is the referential work a draft structurally cannot do,
/// because the model hands back bare ids:
///
///  - the transaction's `accountId` must exist, and its `categoryKind` has to
///    be resolved from `categoryId` (the draft demands the kind, the model
///    only gives an id);
///  - a budget's unknown category/account ids are **filtered out**, not
///    rejected. A budget that ends up broader than intended is visible on its
///    own card and fixable in two taps; losing the whole action because one
///    stale id slipped through is not.
@injectable
class ExecuteAiAction {
  const ExecuteAiAction(
    this._createBudget,
    this._createGoal,
    this._createCategory,
    this._createTransaction,
    this._getCategory,
    this._accounts,
    this._linkTransactionToDebt,
    this._debts,
  );

  /// The field a failed debt reference is reported on, mirroring the name
  /// `LinkTransactionToDebt` already uses for the same id.
  static const String _fieldDebtId = 'debtId';

  final CreateBudget _createBudget;
  final CreateGoal _createGoal;
  final CreateCategory _createCategory;
  final CreateTransaction _createTransaction;
  final GetCategory _getCategory;
  final AccountRepository _accounts;
  final LinkTransactionToDebt _linkTransactionToDebt;
  final DebtRepository _debts;

  FutureResult<AiActionOutcome> call(AiActionProposal proposal) async =>
      switch (proposal) {
        CreateBudgetProposal() => _budget(proposal),
        CreateGoalProposal() => _goal(proposal),
        CreateCategoryProposal() => _category(proposal),
        CreateTransactionProposal() => _transaction(proposal),
        LinkTransactionToDebtProposal() => _debtLink(proposal),
        UnsupportedProposal() => Future.value(
            Left<Failure, AiActionOutcome>(
              ValidationFailure(
                'proposal kind "${proposal.rawKind}" is not supported by this '
                'app version',
              ),
            ),
          ),
      };

  FutureResult<AiActionOutcome> _budget(CreateBudgetProposal proposal) async {
    final categoryIds = <String>{};
    for (final id in proposal.categoryIds) {
      final category = await _getCategory(id);
      if (category.isRight()) {
        categoryIds.add(id);
      }
    }

    final accountIds = <String>{};
    for (final id in proposal.accountIds) {
      final account = await _accounts.getAccount(id);
      if (account.isRight()) {
        accountIds.add(id);
      }
    }

    final result = await _createBudget(
      BudgetDraft(
        name: proposal.name,
        amountMinor: proposal.amountMinor,
        currency: proposal.currency,
        period: proposal.period,
        startDate: proposal.startDate,
        recurring: proposal.recurring,
        categoryIds: categoryIds,
        accountIds: accountIds,
      ),
    );

    return result.map(
      (budget) => AiActionOutcome(
        proposalId: proposal.id,
        entity: AiActionEntity.budget,
        entityId: budget.id,
      ),
    );
  }

  FutureResult<AiActionOutcome> _goal(CreateGoalProposal proposal) async {
    final result = await _createGoal(
      GoalDraft(
        name: proposal.name,
        targetMinor: proposal.targetMinor,
        currency: proposal.currency,
        accountId: proposal.accountId,
        targetDate: proposal.targetDate,
      ),
    );

    return result.map(
      (goal) => AiActionOutcome(
        proposalId: proposal.id,
        entity: AiActionEntity.goal,
        entityId: goal.id,
      ),
    );
  }

  FutureResult<AiActionOutcome> _category(
    CreateCategoryProposal proposal,
  ) async {
    final result = await _createCategory(
      CategoryDraft(
        name: proposal.name,
        kind: proposal.kind,
        parentId: proposal.parentId,
      ),
    );

    return result.map(
      (category) => AiActionOutcome(
        proposalId: proposal.id,
        entity: AiActionEntity.category,
        entityId: category.id,
      ),
    );
  }

  FutureResult<AiActionOutcome> _transaction(
    CreateTransactionProposal proposal,
  ) async {
    final accountResult = await _accounts.getAccount(proposal.accountId);
    if (accountResult case Left(value: final failure)) {
      return Left(
          _asReferenceFailure(failure, TransactionDraft.fieldAccountId));
    }

    CategoryKind? categoryKind;
    final categoryId = proposal.categoryId;
    if (categoryId != null) {
      final categoryResult = await _getCategory(categoryId);
      if (categoryResult case Left(value: final failure)) {
        return Left(
          _asReferenceFailure(failure, TransactionDraft.fieldCategoryId),
        );
      }
      categoryKind = categoryResult.fold((_) => null, (c) => c.kind);
    }

    // A movement can be born attributed to a debt (`debtId` on the write
    // tool), which spares the user a second confirmation. The debt is resolved
    // here — not inside the draft — because the draft cannot reach a
    // repository, and because the two rules that follow both need the row: a
    // closed debt accepts nothing new (same rule `LinkTransactionToDebt`
    // enforces for the after-the-fact link), and `countsInBudget` follows from
    // `direction` × `type` (`DebtEventRules`, the single source of that
    // truth), exactly as `RegisterDebtCashEvent` resolves it.
    var countsInBudget = false;
    final debtId = proposal.debtId;
    if (debtId != null) {
      final debtResult = await _debts.getDebt(debtId);
      if (debtResult case Left(value: final failure)) {
        return Left(_asReferenceFailure(failure, _fieldDebtId));
      }
      final Debt? debt = debtResult.getRight().toNullable();
      if (debt == null) {
        return const Left(
          ValidationFailure('that debt does not exist', field: _fieldDebtId),
        );
      }
      if (debt.isClosed) {
        return const Left(
          ValidationFailure(
            'a closed debt accepts no new links',
            field: _fieldDebtId,
          ),
        );
      }
      countsInBudget = DebtEventRules.countsInBudgetFor(
        direction: debt.direction,
        type: proposal.type,
      );
    }

    final result = await _createTransaction(
      TransactionDraft(
        accountId: proposal.accountId,
        amountMinor: proposal.amountMinor,
        currency: proposal.currency,
        type: proposal.type,
        date: proposal.date,
        categoryId: categoryId,
        categoryKind: categoryKind,
        note: proposal.note,
        debtId: debtId,
        countsInBudget: countsInBudget,
        // TODO(cami): add an `ai` value to TransactionSource once the sync
        // side is settled. `TxSource` is a synchronised column read with
        // Drift's `textEnum`, which throws on a value it does not know — so an
        // older client that pulls a row written by a newer one would crash
        // reading its own ledger. Rolling that out needs a migration plan of
        // its own, and nothing depends on it today: AI usage is already
        // measured server-side in `ai_usage_log`.
        // ignore: avoid_redundant_argument_values
        source: TransactionSource.manual,
      ),
    );

    return result.map(
      (transaction) => AiActionOutcome(
        proposalId: proposal.id,
        entity: AiActionEntity.transaction,
        entityId: transaction.id,
      ),
    );
  }

  /// Attributes an existing movement to a debt. Nothing is created here: the
  /// movement already moved its account, and `LinkTransactionToDebt` owns both
  /// gates the server structurally cannot apply — the ids must resolve to a
  /// real transaction and a real debt, and the debt must be open.
  FutureResult<AiActionOutcome> _debtLink(
    LinkTransactionToDebtProposal proposal,
  ) async {
    final result = await _linkTransactionToDebt(
      transactionId: proposal.transactionId,
      debtId: proposal.debtId,
    );

    return result.map(
      (_) => AiActionOutcome(
        proposalId: proposal.id,
        entity: AiActionEntity.debtLink,
        entityId: proposal.debtId,
      ),
    );
  }

  /// A missing referent is a bad proposal, not a missing screen: reported as a
  /// validation error on the offending field so the card can say which id the
  /// model got wrong.
  Failure _asReferenceFailure(Failure failure, String field) =>
      failure is NotFoundFailure
          ? ValidationFailure(failure.message, field: field)
          : failure;
}
