import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/entities/transaction.dart';

/// The already-extracted fields of one notification, as handed over by the
/// native listener's buffer (HU-03). Input of `IngestParsedCaptures`.
///
/// **This is the boundary where zero retention is enforced.** There is
/// deliberately no `rawText`/`title`/`bigText` field: the notification body
/// is parsed and discarded inside the native process, and only these
/// structured fields cross over. Any code that needs the literal text to do
/// its job is mis-designed.
class ParsedCapture extends Equatable {
  const ParsedCapture({
    required this.sourcePackage,
    required this.postedAt,
    required this.amountMinor,
    required this.currency,
    required this.entryType,
    this.source = TransactionSource.notification,
    this.sourceRuleId,
    this.merchantRaw,
    this.accountHint,
  });

  static const String fieldSourcePackage = 'sourcePackage';
  static const String fieldAmountMinor = 'amountMinor';
  static const String fieldCurrency = 'currency';
  static const String fieldEntryType = 'entryType';
  static const String fieldAccountHint = 'accountHint';

  /// Last-4 hints are exactly that: four digits. Anything longer is not a
  /// last-4 and is refused rather than silently truncated.
  static const int accountHintLength = 4;

  static final RegExp _currencyPattern = RegExp(r'^[A-Z]{3}$');
  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  final TransactionSource source;
  final String sourcePackage;
  final String? sourceRuleId;
  final DateTime postedAt;
  final int amountMinor;
  final String currency;
  final TransactionType entryType;
  final String? merchantRaw;
  final String? accountHint;

  /// Validates the fields a capture cannot exist without and returns a
  /// **normalized** copy: trimmed package/rule/merchant, upper-cased
  /// currency, blank strings turned into `null`.
  ///
  /// Rejected (never persisted as a half-capture):
  ///  - a non-positive amount — the sign belongs to [entryType], and a
  ///    capture without a real amount saves no typing, it only adds noise to
  ///    the inbox (HU-03);
  ///  - a currency that is not an ISO-4217 code;
  ///  - a transfer: a notification never says which two accounts moved money
  ///    between them, so it can only be an income or an expense;
  ///  - an account hint that is not exactly four digits.
  Result<ParsedCapture> validated() {
    final sourcePackage = this.sourcePackage.trim();
    if (sourcePackage.isEmpty) {
      return const Left(
        ValidationFailure(
          'a capture must record the issuer package',
          field: fieldSourcePackage,
        ),
      );
    }

    if (amountMinor <= 0) {
      return const Left(
        ValidationFailure(
          'the amount must be a positive integer of cents',
          field: fieldAmountMinor,
        ),
      );
    }

    final currency = this.currency.trim().toUpperCase();
    if (!_currencyPattern.hasMatch(currency)) {
      return const Left(
        ValidationFailure(
          'currency must be a 3-letter ISO-4217 code',
          field: fieldCurrency,
        ),
      );
    }

    if (entryType == TransactionType.transfer) {
      return const Left(
        ValidationFailure(
          'a capture is either an income or an expense, never a transfer',
          field: fieldEntryType,
        ),
      );
    }

    final accountHint = _blankToNull(this.accountHint);
    if (accountHint != null &&
        (accountHint.length != accountHintLength ||
            !_digitsOnly.hasMatch(accountHint))) {
      return const Left(
        ValidationFailure(
          'the account hint must be exactly 4 digits',
          field: fieldAccountHint,
        ),
      );
    }

    return Right(
      ParsedCapture(
        source: source,
        sourcePackage: sourcePackage,
        sourceRuleId: _blankToNull(sourceRuleId),
        postedAt: postedAt,
        amountMinor: amountMinor,
        currency: currency,
        entryType: entryType,
        merchantRaw: _blankToNull(merchantRaw),
        accountHint: accountHint,
      ),
    );
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  List<Object?> get props => [
        source,
        sourcePackage,
        sourceRuleId,
        postedAt,
        amountMinor,
        currency,
        entryType,
        merchantRaw,
        accountHint,
      ];
}
