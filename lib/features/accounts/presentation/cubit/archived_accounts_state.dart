import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/account_with_balance.dart';

enum ArchivedAccountsStatus { loading, ready, failure }

/// State of "Cuentas archivadas" (`ft48Z`/`eAwin`, HU-07).
class ArchivedAccountsState extends Equatable {
  const ArchivedAccountsState({
    this.status = ArchivedAccountsStatus.loading,
    this.accounts = const [],
    this.failure,
  });

  final ArchivedAccountsStatus status;
  final List<AccountWithBalance> accounts;
  final Failure? failure;

  bool get isEmpty =>
      status == ArchivedAccountsStatus.ready && accounts.isEmpty;

  ArchivedAccountsState copyWith({
    ArchivedAccountsStatus? status,
    List<AccountWithBalance>? accounts,
    Failure? failure,
  }) =>
      ArchivedAccountsState(
        status: status ?? this.status,
        accounts: accounts ?? this.accounts,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, accounts, failure];
}
