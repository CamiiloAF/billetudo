import 'package:equatable/equatable.dart';

import '../../../budgets/domain/entities/budget.dart' show BudgetPeriod;
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../transactions/domain/entities/transaction.dart'
    show TransactionType;

/// Where a proposal card stands for the user.
///
/// [failed] is distinct from [dismissed] on purpose: a proposal whose write
/// blew up must stay on screen offering a retry, while a dismissed one is a
/// decision the user already made.
enum AiProposalStatus { pending, confirmed, dismissed, failed }

/// A write the model **suggested** and nobody executed.
///
/// The backend never runs a write tool (`supabase/functions/README.md`,
/// "Escritura — nunca se ejecutan"): it validates the model's call and emits
/// it as a `proposals[]` entry. The app renders a card; only a tap reaches
/// `ExecuteAiAction`.
///
/// Sealed so `ExecuteAiAction` switches exhaustively: adding a proposal kind
/// without wiring its write becomes a compile error rather than a silently
/// dead button.
sealed class AiActionProposal extends Equatable {
  const AiActionProposal({
    required this.id,
    required this.title,
    required this.status,
  });

  /// The tool-call id the backend assigned. Stable within one turn only, but
  /// unique inside the message it belongs to, which is all the history needs
  /// to address a single card.
  final String id;

  /// One sentence, already in the user's language, written by the model (the
  /// `rationale` argument of the write tool). Shown verbatim on the card.
  final String title;

  final AiProposalStatus status;

  /// A copy with [status] replaced. Declared here so a caller holding the
  /// sealed supertype can advance a card's state without re-switching on the
  /// concrete kind.
  AiActionProposal withStatus(AiProposalStatus status);

  @override
  List<Object?> get props => [id, title, status];
}

/// `kind: "create_budget"`.
final class CreateBudgetProposal extends AiActionProposal {
  const CreateBudgetProposal({
    required super.id,
    required super.title,
    required super.status,
    required this.name,
    required this.amountMinor,
    required this.currency,
    required this.period,
    required this.startDate,
    required this.recurring,
    this.categoryIds = const <String>{},
    this.accountIds = const <String>{},
  });

  final String name;

  /// Always a positive integer of cents; the backend rejects anything else
  /// before it ever becomes a proposal.
  final int amountMinor;

  final String currency;
  final BudgetPeriod period;
  final DateTime startDate;
  final bool recurring;

  /// Empty = every category, matching `BudgetDraft`'s inclusive-empty scope.
  /// Ids that no longer exist are filtered out by `ExecuteAiAction`, never
  /// rejected — see its doc.
  final Set<String> categoryIds;

  /// Empty = every account, same inclusive-empty rule as [categoryIds].
  final Set<String> accountIds;

  @override
  CreateBudgetProposal withStatus(AiProposalStatus status) =>
      CreateBudgetProposal(
        id: id,
        title: title,
        status: status,
        name: name,
        amountMinor: amountMinor,
        currency: currency,
        period: period,
        startDate: startDate,
        recurring: recurring,
        categoryIds: categoryIds,
        accountIds: accountIds,
      );

  @override
  List<Object?> get props => [
        ...super.props,
        name,
        amountMinor,
        currency,
        period,
        startDate,
        recurring,
        categoryIds,
        accountIds,
      ];
}

/// `kind: "create_goal"`.
final class CreateGoalProposal extends AiActionProposal {
  const CreateGoalProposal({
    required super.id,
    required super.title,
    required super.status,
    required this.name,
    required this.targetMinor,
    required this.currency,
    this.targetDate,
    this.accountId,
  });

  final String name;
  final int targetMinor;
  final String currency;
  final DateTime? targetDate;

  /// When set, `CreateGoal` forces the goal's currency to the account's, so
  /// [currency] here is only a fallback for an account-less goal.
  final String? accountId;

  @override
  CreateGoalProposal withStatus(AiProposalStatus status) => CreateGoalProposal(
        id: id,
        title: title,
        status: status,
        name: name,
        targetMinor: targetMinor,
        currency: currency,
        targetDate: targetDate,
        accountId: accountId,
      );

  @override
  List<Object?> get props =>
      [...super.props, name, targetMinor, currency, targetDate, accountId];
}

/// `kind: "create_category"`.
final class CreateCategoryProposal extends AiActionProposal {
  const CreateCategoryProposal({
    required super.id,
    required super.title,
    required super.status,
    required this.name,
    required this.kind,
    this.parentId,
  });

  final String name;

  /// Ignored by `CreateCategory` when [parentId] is set: a subcategory always
  /// inherits its parent's kind.
  final CategoryKind kind;

  final String? parentId;

  @override
  CreateCategoryProposal withStatus(AiProposalStatus status) =>
      CreateCategoryProposal(
        id: id,
        title: title,
        status: status,
        name: name,
        kind: kind,
        parentId: parentId,
      );

  @override
  List<Object?> get props => [...super.props, name, kind, parentId];
}

/// `kind: "create_transaction"`.
final class CreateTransactionProposal extends AiActionProposal {
  const CreateTransactionProposal({
    required super.id,
    required super.title,
    required super.status,
    required this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.type,
    required this.date,
    this.categoryId,
    this.note,
  });

  final String accountId;
  final int amountMinor;
  final String currency;

  /// The write tool only offers `income`/`expense`; `transfer` is not
  /// proposable (it needs a destination account the model has no way to
  /// disambiguate), but the domain type is the full enum so the switch in
  /// `TransactionDraft` stays the only place that reasons about direction.
  final TransactionType type;

  final DateTime date;

  /// The model only ever hands back an id. `ExecuteAiAction` resolves its
  /// `kind`, which `TransactionDraft.validated` requires.
  final String? categoryId;

  final String? note;

  @override
  CreateTransactionProposal withStatus(AiProposalStatus status) =>
      CreateTransactionProposal(
        id: id,
        title: title,
        status: status,
        accountId: accountId,
        amountMinor: amountMinor,
        currency: currency,
        type: type,
        date: date,
        categoryId: categoryId,
        note: note,
      );

  @override
  List<Object?> get props => [
        ...super.props,
        accountId,
        amountMinor,
        currency,
        type,
        date,
        categoryId,
        note,
      ];
}

/// A proposal this app version cannot act on: an unknown `kind`, or a payload
/// that did not parse.
///
/// It exists so the mapper never throws and never drops. A thread persisted
/// today has to keep parsing when the backend contract grows
/// (`supabase/functions/README.md`: "Cualquier otro valor debe degradar a
/// `UnsupportedProposal` en el cliente, nunca lanzar"). The card renders as
/// plain text with no confirm button — the user still reads what the model
/// said, they just cannot execute it here.
final class UnsupportedProposal extends AiActionProposal {
  const UnsupportedProposal({
    required super.id,
    required super.title,
    required super.status,
    required this.rawKind,
  });

  /// The `kind` string as it arrived, kept for diagnostics.
  final String rawKind;

  @override
  UnsupportedProposal withStatus(AiProposalStatus status) =>
      UnsupportedProposal(
        id: id,
        title: title,
        status: status,
        rawKind: rawKind,
      );

  @override
  List<Object?> get props => [...super.props, rawKind];
}
