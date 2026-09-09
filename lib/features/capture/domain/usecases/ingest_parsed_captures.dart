import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/capture_ingestion.dart';
import '../entities/parsed_capture.dart';
import '../entities/pending_capture.dart';
import '../repositories/issuer_settings_repository.dart';
import '../repositories/pending_capture_repository.dart';
import 'suggest_account_for_capture.dart';
import 'suggest_category_for_merchant.dart';

/// Turns the already-parsed fields the native listener buffered into rows of
/// the review inbox (HU-04).
///
/// **It never creates a `Transaction`.** Every capture lands as `pending` and
/// waits for a human decision; the app has no "register automatically what it
/// detects" mode and will not have one.
///
/// Two guards run before anything is written:
///  - **the issuer switch** (HU-02). The native side already filters by
///    `packageName` before reading a notification's content; this repeats the
///    check against the switch as it stands *now*, so a capture buffered
///    while an issuer was on never lands after the user turned it off.
///  - **field validation** (`ParsedCapture.validated`). An invalid capture is
///    dropped, not stored half-formed: a row with no usable amount saves no
///    typing, it only adds noise to the inbox.
///
/// Dropping is silent by design — there is no notification text to report
/// back with (zero retention), and nothing about a skipped capture is logged
/// or persisted.
@injectable
class IngestParsedCaptures {
  const IngestParsedCaptures(
    this._repository,
    this._issuers,
    this._suggestAccount,
    this._suggestCategory,
  );

  final PendingCaptureRepository _repository;
  final IssuerSettingsRepository _issuers;
  final SuggestAccountForCapture _suggestAccount;
  final SuggestCategoryForMerchant _suggestCategory;

  FutureResult<List<PendingCapture>> call(List<ParsedCapture> captures) async {
    if (captures.isEmpty) {
      return const Right(<PendingCapture>[]);
    }

    final catalogResult = await _issuers.getIssuerCatalog();
    if (catalogResult case Left(value: final failure)) {
      return Left(failure);
    }
    final enabled = catalogResult
        .getOrElse((_) => const [])
        .where((issuer) => issuer.enabled)
        .map((issuer) => issuer.packageName)
        .toSet();

    final ingestions = <CaptureIngestion>[];
    for (final capture in captures) {
      final validated = capture.validated();
      if (validated case Left()) {
        continue;
      }
      final parsed = validated.getOrElse((_) => capture);
      if (!enabled.contains(parsed.sourcePackage)) {
        continue;
      }

      final accountResult = await _suggestAccount(parsed.accountHint);
      final categoryResult = await _suggestCategory(parsed.merchantRaw);
      ingestions.add(
        CaptureIngestion(
          parsed: parsed,
          // A failed lookup only costs a suggestion, never the capture: the
          // user still gets the movement, they just fill that field in.
          suggestedAccountId: accountResult.getOrElse((_) => null),
          suggestedCategoryId: categoryResult.getOrElse((_) => null),
        ),
      );
    }

    if (ingestions.isEmpty) {
      return const Right(<PendingCapture>[]);
    }
    return _repository.ingestParsedCaptures(ingestions);
  }
}
