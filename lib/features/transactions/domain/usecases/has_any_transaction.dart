import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/transaction_repository.dart';

/// Whether the app has any active (non-trashed) transaction at all — the
/// single source of truth Import/Export checks before deciding between the
/// hub's `Am9cg` empty state and the export form's `calDR` empty state.
///
/// Backed by [TransactionRepository.watchActiveTransactionsCount] — no
/// filter, no join, just a count. Same shape as
/// `HasAnyActiveAccount`/`AccountRepository.watchActiveAccountsCount`: a
/// query failure degrades to `false`, so an infrastructure error surfaces as
/// "no movements yet" rather than as a crash.
@injectable
class HasAnyTransaction {
  const HasAnyTransaction(this._repository);

  final TransactionRepository _repository;

  Stream<bool> call() => _repository.watchActiveTransactionsCount().map(
        (result) => switch (result) {
          Right(value: final count) => count > 0,
          Left() => false,
        },
      );
}
