import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../entities/legal_document.dart';
import '../entities/legal_document_kind.dart';
import '../repositories/legal_documents_repository.dart';

/// Resolves the document to actually show for a [LegalDocumentKind]: cache
/// first, bundled asset fallback. Used by the viewer and by the
/// acceptance/re-acceptance sheets to know exactly which version is about to
/// be accepted.
@lazySingleton
class ResolveLegalDocument {
  const ResolveLegalDocument(this._repository);

  final LegalDocumentsRepository _repository;

  FutureResult<LegalDocument> call({required LegalDocumentKind kind}) =>
      _repository.resolveDocument(kind);
}
