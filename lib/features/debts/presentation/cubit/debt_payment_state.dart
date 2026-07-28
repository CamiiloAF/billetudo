import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../domain/entities/debt.dart';

/// The lifecycle of the registrar-abono sheet.
enum DebtPaymentStatus { loading, ready, saving, saved, failure }

/// The registrar-abono sheet state (`xbsY3` Sí / `V6Z9ln` No, HU-02).
///
/// The toggle [addToAccount] chooses the write: `true` registers a cash
/// `Transaction` carrying the debt id (moves [selectedAccountId]); `false`
/// records a cash-less `DebtEntry`. The concrete income/expense of a cash
/// abono is derived in the domain from the debt's direction — the sheet never
/// picks it.
class DebtPaymentState extends Equatable {
  const DebtPaymentState({
    required this.debt,
    this.status = DebtPaymentStatus.loading,
    this.accounts = const [],
    this.addToAccount = true,
    this.selectedAccountId,
    this.amountMinor = 0,
    required this.date,
    this.note = '',
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.failure,
  });

  final Debt debt;
  final DebtPaymentStatus status;
  final List<AccountWithBalance> accounts;
  final bool addToAccount;
  final String? selectedAccountId;
  final int amountMinor;
  final DateTime date;
  final String note;

  /// Optional budget attribution, only meaningful (and only shown) when
  /// [addToAccount] is `true` — a cash-less abono is not a `Transaction`, so a
  /// category has nowhere to live (`V6Z9ln` hides it).
  final String? categoryId;
  final String? categoryName;

  /// The chosen category's Lucide icon name/palette token (fix: the "Categoría"
  /// field used to always show a fixed `tag` glyph instead of the real
  /// category appearance) — resolved via `CategoryAppearance` in the sheet, not
  /// here, so this stays a pure domain-adjacent string pair.
  final String? categoryIcon;
  final String? categoryColor;

  final Failure? failure;

  bool get isSaving => status == DebtPaymentStatus.saving;

  /// The account currently chosen, or null when none is selected / available.
  AccountWithBalance? get selectedAccount {
    for (final entry in accounts) {
      if (entry.account.id == selectedAccountId) {
        return entry;
      }
    }
    return null;
  }

  /// The CTA is enabled once there is a positive amount and — when adding to
  /// an account — a selected account AND a category (fix 7: the category is
  /// mandatory for a cash abono, same rule regular transactions follow;
  /// preselected in `DebtPaymentCubit.start` but the user can still clear it
  /// via the picker).
  bool get canSubmit =>
      amountMinor > 0 &&
      !isSaving &&
      (!addToAccount || (selectedAccountId != null && categoryId != null));

  DebtPaymentState copyWith({
    DebtPaymentStatus? status,
    List<AccountWithBalance>? accounts,
    bool? addToAccount,
    String? Function()? selectedAccountId,
    int? amountMinor,
    DateTime? date,
    String? note,
    String? Function()? categoryId,
    String? Function()? categoryName,
    String? Function()? categoryIcon,
    String? Function()? categoryColor,
    Failure? Function()? failure,
  }) =>
      DebtPaymentState(
        debt: debt,
        status: status ?? this.status,
        accounts: accounts ?? this.accounts,
        addToAccount: addToAccount ?? this.addToAccount,
        selectedAccountId: selectedAccountId == null
            ? this.selectedAccountId
            : selectedAccountId(),
        amountMinor: amountMinor ?? this.amountMinor,
        date: date ?? this.date,
        note: note ?? this.note,
        categoryId: categoryId == null ? this.categoryId : categoryId(),
        categoryName: categoryName == null ? this.categoryName : categoryName(),
        categoryIcon: categoryIcon == null ? this.categoryIcon : categoryIcon(),
        categoryColor:
            categoryColor == null ? this.categoryColor : categoryColor(),
        failure: failure == null ? this.failure : failure(),
      );

  @override
  List<Object?> get props => [
        debt,
        status,
        accounts,
        addToAccount,
        selectedAccountId,
        amountMinor,
        date,
        note,
        categoryId,
        categoryName,
        categoryIcon,
        categoryColor,
        failure,
      ];
}
