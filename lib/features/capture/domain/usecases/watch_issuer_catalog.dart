import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/issuer_catalog_entry.dart';
import '../repositories/issuer_settings_repository.dart';

/// The curated issuer catalog with each switch resolved (HU-02), re-emitted
/// on every change.
///
/// The catalog is closed: only these apps can ever be listened to, and each
/// one starts off. An issuer that is off produces no capture from the moment
/// it is switched off; the captures it already produced stay in the inbox
/// until the user dispatches them.
@injectable
class WatchIssuerCatalog {
  const WatchIssuerCatalog(this._repository);

  final IssuerSettingsRepository _repository;

  Stream<Result<List<IssuerCatalogEntry>>> call() =>
      _repository.watchIssuerCatalog();
}
