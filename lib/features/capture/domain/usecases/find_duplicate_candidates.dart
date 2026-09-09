import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/duplicate_candidate.dart';
import '../entities/issuer_catalog_entry.dart';
import '../entities/pending_capture.dart';
import '../repositories/issuer_settings_repository.dart';
import '../repositories/pending_capture_repository.dart';

/// Finds everything already in the app that may be the same movement as a
/// capture (HU-07), so the user can compare before deciding.
///
/// Two windows, because the two cases are not equally trustworthy:
///  - [transactionWindow] (±48h, wide) against transactions the user already
///    recorded. Someone who buys something on Friday and types it in on
///    Sunday is the most common double entry there is, and an ±1h window
///    would miss exactly that. The price is that two identical coffees on
///    different days get flagged — acceptable, because the result is only a
///    "posible duplicado" mark the user resolves.
///  - [groupingWindow] (minutes, strict) against other pending captures. Two
///    cases live here: the same issuer notifying twice (authorization and
///    settlement) and, above all, the wallet + bank pair of one NFC payment.
///    Matching deliberately does **not** require the same `sourcePackage`:
///    paying with Google Wallet produces one notification from the wallet and
///    another from the card's bank, and requiring the same issuer would let
///    them through as two separate movements.
///
/// **Nothing is merged or discarded here.** This use case reads and returns;
/// every action stays with the user. A false positive would erase a real
/// expense and unbalance the account with no trace, which is worse than the
/// duplicate it would have avoided.
@injectable
class FindDuplicateCandidates {
  const FindDuplicateCandidates(this._repository, this._issuers);

  /// Wide, for the "posible duplicado" mark only.
  static const Duration transactionWindow = Duration(hours: 48);

  /// Strict, for grouping two captures of the same payment. The NFC payment
  /// and the bank's notice are practically simultaneous.
  static const Duration groupingWindow = Duration(minutes: 10);

  final PendingCaptureRepository _repository;
  final IssuerSettingsRepository _issuers;

  FutureResult<List<DuplicateCandidate>> call(PendingCapture capture) async {
    final transactions = await _repository.findMatchingTransactions(
      amountMinor: capture.amountMinor,
      currency: capture.currency,
      around: capture.postedAt,
      window: transactionWindow,
    );
    if (transactions case Left(value: final failure)) {
      return Left(failure);
    }

    final captures = await _repository.findMatchingCaptures(
      excludeId: capture.id,
      amountMinor: capture.amountMinor,
      currency: capture.currency,
      around: capture.postedAt,
      window: groupingWindow,
    );
    if (captures case Left(value: final failure)) {
      return Left(failure);
    }

    final catalog = await _issuers.getIssuerCatalog();
    final kinds = <String, IssuerKind>{
      for (final issuer in catalog.getOrElse((_) => const []))
        issuer.packageName: issuer.kind,
    };

    return Right(<DuplicateCandidate>[
      for (final other in captures.getOrElse((_) => const []))
        CaptureDuplicateCandidate(
          other,
          sameIssuer: other.sourcePackage == capture.sourcePackage,
          // High confidence for the same issuer notifying twice and for the
          // known wallet/bank pairing. Two unrelated issuers coinciding to
          // the minute is not that pattern, so it stays a suggestion.
          confidence: other.sourcePackage == capture.sourcePackage ||
                  _isWalletBankPair(
                    kinds[capture.sourcePackage],
                    kinds[other.sourcePackage],
                  )
              ? DuplicateConfidence.high
              : DuplicateConfidence.possible,
        ),
      for (final transaction in transactions.getOrElse((_) => const []))
        TransactionDuplicateCandidate(
          transaction,
          accountMatches: capture.suggestedAccountId != null &&
              transaction.accountId == capture.suggestedAccountId,
        ),
    ]);
  }

  /// One of the two issuers is a wallet and the other a bank — the shape of a
  /// single NFC payment seen from both sides. When either package is unknown
  /// to the catalog the answer is "no", never a guess.
  bool _isWalletBankPair(IssuerKind? one, IssuerKind? other) =>
      one != null && other != null && one != other;
}
