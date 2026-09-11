import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/issuer_settings_repository.dart';

/// Says which account an issuer's notifications belong to (HU-06), or clears
/// that link with a null `accountId`.
///
/// Configured alongside the issuer switch, because for the issuers that never
/// quote the card digits — Nu and Nequi, verified against real notifications
/// — this is the only way their captures can arrive with an account, and it
/// works from the very first one.
///
/// It never registers anything: what it stores is a suggestion the
/// confirmation form pre-fills and the user can override every time.
@injectable
class LinkIssuerAccount {
  const LinkIssuerAccount(this._repository);

  final IssuerSettingsRepository _repository;

  FutureResult<Unit> call({
    required String packageName,
    required String? accountId,
  }) =>
      _repository.setIssuerAccount(
        packageName: packageName,
        accountId: accountId,
      );
}
