import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/accounts_overview.dart';
import '../repositories/account_repository.dart';

/// Total Card aggregate: one subtotal per currency, never a cross-currency sum.
///
/// Isolated in its own use case so the anti-cross-currency rule has a single
/// place to live and to be tested.
@injectable
class WatchAccountsOverview {
  const WatchAccountsOverview(this._repository);

  final AccountRepository _repository;

  Stream<Result<AccountsOverview>> call() => _repository
      .watchActiveAccounts()
      .map((result) => result.map(AccountsOverview.from));
}
