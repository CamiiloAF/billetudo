import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/pending_capture_repository.dart';

/// Resolves the last-4 hint of a notification to one of the user's accounts
/// (HU-06).
///
/// Matches `Accounts.cardLast4` first and `Accounts.last4` second: the two
/// columns mean different things — `cardLast4` is the physical card, which is
/// what a purchase notification quotes, while `last4` is the account number —
/// and on a card account they frequently carry the same digits. Checking the
/// card first keeps the more specific match from being shadowed by the more
/// generic one.
///
/// Always a SUGGESTION: the confirmation form shows it pre-filled and the
/// user can change it. A hint that matches nothing (or more than one account)
/// returns `null`, and the capture simply arrives without an account instead
/// of with a wrong one.
@injectable
class SuggestAccountForCapture {
  const SuggestAccountForCapture(this._repository);

  final PendingCaptureRepository _repository;

  FutureResult<String?> call(String? accountHint) async {
    final hint = accountHint?.trim();
    if (hint == null || hint.isEmpty) {
      return const Right(null);
    }
    return _repository.findAccountIdByLast4(hint);
  }
}
