import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/usecases/accept_legal_documents.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'legal_documents_repository_mock.dart';

void main() {
  late MockLegalDocumentsRepository repository;
  late AcceptLegalDocuments acceptLegalDocuments;

  setUp(() {
    repository = MockLegalDocumentsRepository();
    acceptLegalDocuments = AcceptLegalDocuments(repository);
  });

  LegalDocument document({
    required LegalDocumentKind kind,
    required int legalVersion,
    required LegalDocumentSource source,
  }) =>
      LegalDocument(
        kind: kind,
        content: 'content',
        legalVersion: legalVersion,
        effectiveDate: DateTime.utc(2026, 1, 1),
        source: source,
      );

  test('persists the manifest version when both documents downloaded fine',
      () async {
    when(
      () => repository.acceptLegalDocuments(
        version: any(named: 'version'),
        acceptedAt: any(named: 'acceptedAt'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    final result = await acceptLegalDocuments(
      shownDocuments: [
        document(
          kind: LegalDocumentKind.privacyPolicy,
          legalVersion: 3,
          source: LegalDocumentSource.cache,
        ),
        document(
          kind: LegalDocumentKind.termsOfUse,
          legalVersion: 3,
          source: LegalDocumentSource.cache,
        ),
      ],
    );

    expect(result.isRight(), isTrue);
    verify(
      () => repository.acceptLegalDocuments(
        version: 3,
        acceptedAt: any(named: 'acceptedAt'),
      ),
    ).called(1);
  });

  test(
    'persists the LOWER version when one document fell back to the bundle — '
    'never the higher version the person was never actually shown',
    () async {
      when(
        () => repository.acceptLegalDocuments(
          version: any(named: 'version'),
          acceptedAt: any(named: 'acceptedAt'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      final result = await acceptLegalDocuments(
        shownDocuments: [
          document(
            kind: LegalDocumentKind.privacyPolicy,
            legalVersion: 3,
            source: LegalDocumentSource.cache,
          ),
          document(
            kind: LegalDocumentKind.termsOfUse,
            // Fell back to the bundle: an older version than the manifest
            // currently declares.
            legalVersion: 1,
            source: LegalDocumentSource.bundle,
          ),
        ],
      );

      expect(result.isRight(), isTrue);
      verify(
        () => repository.acceptLegalDocuments(
          version: 1,
          acceptedAt: any(named: 'acceptedAt'),
        ),
      ).called(1);
    },
  );

  test('fails validation instead of accepting an empty set', () async {
    final result = await acceptLegalDocuments(shownDocuments: const []);

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => repository.acceptLegalDocuments(
        version: any(named: 'version'),
        acceptedAt: any(named: 'acceptedAt'),
      ),
    );
  });
}
