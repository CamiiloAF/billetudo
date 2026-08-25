import 'package:equatable/equatable.dart';

/// A savings goal. Pure domain entity: no Drift types, no `double`.
///
/// There is deliberately no stored progress field — `savedMinor` is always
/// DERIVED by summing the goal's `GoalContribution`s (contribution -
/// withdrawal), the same "derive, don't store" pattern `Debts` uses via
/// `DebtEntries`. See `docs/requirements/fase-1/07-metas.md`.
class Goal extends Equatable {
  const Goal({
    required this.id,
    required this.name,
    required this.targetMinor,
    required this.currency,
    required this.lastMilestonePct,
    required this.createdAt,
    required this.updatedAt,
    this.accountId,
    this.targetDate,
    this.icon,
    this.completedAt,
    this.archivedAt,
    this.deletedAt,
  });

  /// UUID as text.
  final String id;

  final String name;

  /// Objective amount in cents. Always > 0.
  final int targetMinor;

  /// ISO-4217 code, e.g. 'COP', 'USD'. Fixed to the linked account's currency
  /// whenever [accountId] is set (HU-02).
  final String currency;

  /// Goal tied to a specific account (HU-02) — opt-in but recommended. `null`
  /// means the goal only accepts tracking-only movements.
  final String? accountId;

  final DateTime? targetDate;
  final String? icon;

  /// Completion timestamp (HU-07). `null` = not completed. Set automatically
  /// the moment derived `savedMinor` reaches 100% of [targetMinor], or when
  /// the user lowers [targetMinor] below the already-saved amount; cleared
  /// again only if [targetMinor] is later raised back above `savedMinor`. A
  /// withdrawal on a completed goal never clears this — the shown progress
  /// freezes at 100% instead (HU-07).
  final DateTime? completedAt;

  /// Archive timestamp (HU-09). `null` = active. Distinct from [deletedAt]
  /// (reversible trash) and the referential tombstone used when purging.
  final DateTime? archivedAt;

  /// Highest celebration threshold (0/25/50/75/100) already crossed and
  /// celebrated (HU-06), so crossing the same one again after a
  /// withdrawal-induced dip does not re-trigger the celebration.
  final int lastMilestonePct;

  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  /// Soft-delete trash timestamp (HU-10). `null` = active. Reversible via
  /// `RestoreGoal`; purging the trash uses a tombstone instead (`Transactions
  /// .goalId` references this row).
  final DateTime? deletedAt;

  bool get isArchived => archivedAt != null;

  bool get isCompleted => completedAt != null;

  bool get isTrashed => deletedAt != null;

  bool get hasAccount => accountId != null;

  @override
  List<Object?> get props => [
        id,
        name,
        targetMinor,
        currency,
        accountId,
        targetDate,
        icon,
        completedAt,
        archivedAt,
        lastMilestonePct,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
