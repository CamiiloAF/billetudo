import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_deletion_impact.dart';
import '../../domain/entities/account_with_balance.dart';

enum AccountDetailStatus {
  loading,
  ready,
  failure,

  /// The account was archived or deleted: the screen has nothing left to show
  /// and the page pops.
  closed,
}

/// Which confirmation the screen is asking for. Only one can be open at a time.
enum AccountDetailPrompt { none, archive, delete, cannotDelete }

class AccountDetailState extends Equatable {
  const AccountDetailState({
    this.status = AccountDetailStatus.loading,
    this.entry,
    this.revealedNumber,
    this.prompt = AccountDetailPrompt.none,
    this.impact,
    this.failure,
  });

  final AccountDetailStatus status;
  final AccountWithBalance? entry;

  /// The full account number **while it is revealed** (HU-03).
  ///
  /// Deliberately part of the state and nothing else: it is read from secure
  /// storage on demand and dropped on hide, so a fresh cubit always starts
  /// masked. It is never persisted.
  final String? revealedNumber;

  final AccountDetailPrompt prompt;

  /// What deleting would affect (HU-08). Loaded before asking to confirm.
  final AccountDeletionImpact? impact;

  final Failure? failure;

  Account? get account => entry?.account;

  /// The number starts masked, always.
  bool get isNumberRevealed => revealedNumber != null;

  /// Which figure the card's carousel highlights (HU-04). Debt by default.
  CardBalanceView get cardView =>
      account?.cardBalancePrimary ?? CardBalanceView.debt;

  AccountDetailState copyWith({
    AccountDetailStatus? status,
    AccountWithBalance? entry,
    String? revealedNumber,
    AccountDetailPrompt? prompt,
    AccountDeletionImpact? impact,
    Failure? failure,
  }) =>
      AccountDetailState(
        status: status ?? this.status,
        entry: entry ?? this.entry,
        // Revealing is explicit in both directions: a state built without a
        // number is a masked state (see `AccountDetailCubit.hideNumber`).
        revealedNumber: revealedNumber,
        prompt: prompt ?? this.prompt,
        impact: impact ?? this.impact,
        failure: failure,
      );

  /// [copyWith] drops the revealed number by design; this keeps it across an
  /// unrelated update (e.g. a new balance emission while the user is looking at
  /// the number).
  AccountDetailState copyKeepingNumber({
    AccountDetailStatus? status,
    AccountWithBalance? entry,
    AccountDetailPrompt? prompt,
    AccountDeletionImpact? impact,
    Failure? failure,
  }) =>
      copyWith(
        status: status,
        entry: entry,
        revealedNumber: revealedNumber,
        prompt: prompt,
        impact: impact,
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        entry,
        revealedNumber,
        prompt,
        impact,
        failure,
      ];
}
