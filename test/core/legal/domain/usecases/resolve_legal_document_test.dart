import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/usecases/resolve_legal_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'legal_documents_repository_mock.dart';

void main() {
  test('delegates to the repository for the requested kind', () async {
    final repository = MockLegalDocumentsRepository();
    final document = LegalDocument(
      kind: LegalDocumentKind.termsOfUse,
      content: 'x',
      legalVersion: 1,
      effectiveDate: DateTime.utc(2026, 1, 1),
      source: LegalDocumentSource.bundle,
    );
    when(() => repository.resolveDocument(LegalDocumentKind.termsOfUse))
        .thenAnswer((_) async => Right(document));
    final resolveLegalDocument = ResolveLegalDocument(repository);

    final result =
        await resolveLegalDocument(kind: LegalDocumentKind.termsOfUse);

    expect(
      result.getOrElse((_) => throw StateError('expected Right')),
      document,
    );
    verify(() => repository.resolveDocument(LegalDocumentKind.termsOfUse))
        .called(1);
  });
}
