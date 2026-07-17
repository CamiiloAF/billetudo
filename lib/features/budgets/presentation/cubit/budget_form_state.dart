import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_draft.dart';

enum BudgetFormStatus { loading, ready, failure }

/// State of the create/edit budget form (HU-01/HU-03/HU-09).
///
/// It holds raw field values plus the parsed [amountMinor]; validation itself
/// lives in [BudgetDraft.validated], not here. [canSubmit] mirrors only the
/// bare gate the design asks for (valid name + positive amount) so the CTA can
/// enable early; the full rule set runs on submit.
class BudgetFormState extends Equatable {
  const BudgetFormState({
    this.status = BudgetFormStatus.loading,
    this.id,
    this.name = '',
    this.icon,
    this.amountMinor,
    this.currency = defaultCurrency,
    this.recurring = true,
    this.period = BudgetPeriod.monthly,
    required this.startDate,
    this.endDate,
    this.alertThresholdPct = defaultThreshold,
    this.accountIds = const {},
    this.categoryIds = const {},
    this.submitting = false,
    this.savedId,
    this.failure,
  });

  /// Empty form anchored at [now]. Kept out of the const default so the anchor
  /// is the real "today", not compile time.
  factory BudgetFormState.initial(DateTime now) => BudgetFormState(
        status: BudgetFormStatus.ready,
        startDate: DateTime(now.year, now.month, now.day),
      );

  /// Placeholder while the edit form loads; its [startDate] is unused until the
  /// real state lands.
  factory BudgetFormState.loading() =>
      BudgetFormState(startDate: DateTime(1970));

  static const String defaultCurrency = 'COP';
  static const int defaultThreshold = 80;

  final BudgetFormStatus status;

  /// null when creating; the budget id when editing.
  final String? id;
  final String name;
  final String? icon;
  final int? amountMinor;
  final String currency;
  final bool recurring;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime? endDate;
  final int? alertThresholdPct;
  final Set<String> accountIds;
  final Set<String> categoryIds;
  final bool submitting;

  /// Set once the save succeeds, so the page can pop.
  final String? savedId;
  final Failure? failure;

  bool get isEditing => id != null;

  /// One-off = the `custom` period; a single window with a mandatory end.
  bool get isOneOff => !recurring;

  /// Custom scope selected (either dimension narrowed). Drives the progressive
  /// disclosure of the "Cuentas/Categorías" rows.
  bool get isCustomScope => accountIds.isNotEmpty || categoryIds.isNotEmpty;

  /// Bare CTA gate (HU-01): a valid name and a positive amount. The full rule
  /// set (dates, threshold range) runs in [BudgetDraft.validated] on submit.
  bool get canSubmit {
    final trimmed = name.trim();
    final amount = amountMinor;
    return trimmed.isNotEmpty &&
        trimmed.length <= BudgetDraft.maxNameLength &&
        amount != null &&
        amount > 0;
  }

  BudgetDraft toDraft() => BudgetDraft(
        id: id,
        name: name,
        icon: icon,
        amountMinor: amountMinor ?? 0,
        currency: currency,
        period: recurring ? period : BudgetPeriod.custom,
        startDate: startDate,
        recurring: recurring,
        endDate: endDate,
        alertThresholdPct: alertThresholdPct,
        accountIds: accountIds,
        categoryIds: categoryIds,
      );

  BudgetFormState copyWith({
    BudgetFormStatus? status,
    String? name,
    bool clearIcon = false,
    String? icon,
    bool clearAmount = false,
    int? amountMinor,
    String? currency,
    bool? recurring,
    BudgetPeriod? period,
    DateTime? startDate,
    bool clearEndDate = false,
    DateTime? endDate,
    bool clearThreshold = false,
    int? alertThresholdPct,
    Set<String>? accountIds,
    Set<String>? categoryIds,
    bool? submitting,
    String? savedId,
    Failure? failure,
  }) =>
      BudgetFormState(
        status: status ?? this.status,
        id: id,
        name: name ?? this.name,
        icon: clearIcon ? null : (icon ?? this.icon),
        amountMinor: clearAmount ? null : (amountMinor ?? this.amountMinor),
        currency: currency ?? this.currency,
        recurring: recurring ?? this.recurring,
        period: period ?? this.period,
        startDate: startDate ?? this.startDate,
        endDate: clearEndDate ? null : (endDate ?? this.endDate),
        alertThresholdPct: clearThreshold
            ? null
            : (alertThresholdPct ?? this.alertThresholdPct),
        accountIds: accountIds ?? this.accountIds,
        categoryIds: categoryIds ?? this.categoryIds,
        submitting: submitting ?? this.submitting,
        savedId: savedId,
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        id,
        name,
        icon,
        amountMinor,
        currency,
        recurring,
        period,
        startDate,
        endDate,
        alertThresholdPct,
        accountIds,
        categoryIds,
        submitting,
        savedId,
        failure,
      ];
}
