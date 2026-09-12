import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../entities/legal_document.dart';
import '../repositories/legal_documents_repository.dart';

/// Registers joint acceptance ("Acepto") of the legal terms: one row, one
/// timestamp, for both documents.
///
/// The version persisted is the LOWEST [LegalDocument.legalVersion] among
/// `shownDocuments` — never the manifest's declared current version. If one
/// document fell back to the bundle while the other downloaded fine, the
/// joint acceptance can only cover the older of the two: claiming the newer
/// version would record that the person accepted text they were never shown
/// (`docs/legal/entrega-de-documentos-legales.md`, "Qué versión se guarda al
/// aceptar").
@lazySingleton
class AcceptLegalDocuments {
  const AcceptLegalDocuments(this._repository);

  final LegalDocumentsRepository _repository;

  FutureResult<Unit> call({required List<LegalDocument> shownDocuments}) async {
    if (shownDocuments.isEmpty) {
      return const Left(
        ValidationFailure('cannot accept an empty set of legal documents'),
      );
    }
    final version = shownDocuments
        .map((doc) => doc.legalVersion)
        .reduce((a, b) => a < b ? a : b);
    return _repository.acceptLegalDocuments(
      version: version,
      acceptedAt: DateTime.now(),
    );
  }
}
