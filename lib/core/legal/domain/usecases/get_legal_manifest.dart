import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../entities/legal_manifest.dart';
import '../repositories/legal_documents_repository.dart';

/// Reads the legal manifest known right now (cache or bundle fallback),
/// without ever waiting for a download.
@lazySingleton
class GetLegalManifest {
  const GetLegalManifest(this._repository);

  final LegalDocumentsRepository _repository;

  FutureResult<LegalManifest> call() => _repository.getManifest();
}
