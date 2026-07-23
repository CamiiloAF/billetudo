import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_balance_adjustment.dart';

enum AdjustBalanceStatus {
  editing,
  saving,

  /// Applied: the sheet pops.
  saved,
  failure,
}

/// State of the "Ajustar saldo" sheet (Mejora #1).
///
/// The typed figure lives here as **text**, exactly as typed; it only becomes
/// integer cents through [MoneyFormatter]. The signed arithmetic is never done
/// here — it is delegated to [AccountBalanceAdjustment].
class AdjustBalanceState extends Equatable {
  const AdjustBalanceState({
    this.status = AdjustBalanceStatus.editing,
    this.account,
    this.currentBalanceMinor = 0,
    this.newBalanceText = '',
    this.mode = BalanceAdjustmentMode.registerMovement,
    this.failure,
  });

  final AdjustBalanceStatus status;

  /// The account being adjusted; `null` before the cubit starts.
  final Account? account;

  /// Its current real balance in cents (negative = debt on a card).
  final int currentBalanceMinor;

  /// The new figure the user is typing, in displayed units (debt for a card).
  final String newBalanceText;

  final BalanceAdjustmentMode mode;
  final Failure? failure;

  bool get isCard => account?.type.isCard ?? false;

  String get currency => account?.currency ?? AccountFormDefaults.currency;

  /// The current figure as the user sees it: debt for a card (a positive
  /// number), the plain signed balance otherwise.
  int get displayedCurrentMinor =>
      isCard ? -currentBalanceMinor : currentBalanceMinor;

  /// The typed figure in cents, or `null` when it is empty or unparseable.
  int? get newDisplayedBalanceMinor => newBalanceText.trim().isEmpty
      ? null
      : MoneyFormatter.parseMinor(newBalanceText);

  /// The computed adjustment, or `null` until a valid figure is typed.
  AccountBalanceAdjustment? get adjustment {
    final account = this.account;
    final newDisplayed = newDisplayedBalanceMinor;
    if (account == null || newDisplayed == null) {
      return null;
    }
    return AccountBalanceAdjustment.from(
      account: account,
      currentBalanceMinor: currentBalanceMinor,
      newDisplayedBalanceMinor: newDisplayed,
    );
  }

  /// Whether "Aplicar" can run: a valid figure that actually changes something.
  bool get canApply =>
      status != AdjustBalanceStatus.saving && (adjustment?.hasChange ?? false);

  AdjustBalanceState copyWith({
    AdjustBalanceStatus? status,
    Account? account,
    int? currentBalanceMinor,
    String? newBalanceText,
    BalanceAdjustmentMode? mode,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      AdjustBalanceState(
        status: status ?? this.status,
        account: account ?? this.account,
        currentBalanceMinor: currentBalanceMinor ?? this.currentBalanceMinor,
        newBalanceText: newBalanceText ?? this.newBalanceText,
        mode: mode ?? this.mode,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [
        status,
        account,
        currentBalanceMinor,
        newBalanceText,
        mode,
        failure,
      ];
}

/// The default the sheet falls back to before [AdjustBalanceState.account] is
/// set. Mirrors `AccountFormState.defaultCurrency`.
class AccountFormDefaults {
  const AccountFormDefaults._();

  static const String currency = 'COP';
}
