import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/entities/legal_manifest.dart';
import 'package:billetudo/core/legal/domain/usecases/get_changed_legal_documents.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const getChangedLegalDocuments = GetChangedLegalDocuments();

  test('lists both documents when both changed since the accepted version', () {
    final manifest = LegalManifest(
      currentVersion: 3,
      minAppVersion: '1.0.0',
      documents: [
        LegalManifestDocument(
          kind: LegalDocumentKind.privacyPolicy,
          url: 'https://example.com/privacy',
          changedInVersion: 3,
          effectiveDate: DateTime.utc(2026, 1, 1),
        ),
        LegalManifestDocument(
          kind: LegalDocumentKind.termsOfUse,
          url: 'https://example.com/terms',
          changedInVersion: 2,
          effectiveDate: DateTime.utc(2026, 1, 1),
        ),
      ],
    );

    final changed =
        getChangedLegalDocuments(acceptedVersion: 1, manifest: manifest);

    expect(changed, hasLength(2));
  });

  test(
    'lists only the single document that changed — the re-acceptance sheet '
    'must show singular copy for this case',
    () {
      final manifest = LegalManifest(
        currentVersion: 3,
        minAppVersion: '1.0.0',
        documents: [
          LegalManifestDocument(
            kind: LegalDocumentKind.privacyPolicy,
            url: 'https://example.com/privacy',
            changedInVersion: 3,
            effectiveDate: DateTime.utc(2026, 1, 1),
          ),
          LegalManifestDocument(
            kind: LegalDocumentKind.termsOfUse,
            url: 'https://example.com/terms',
            changedInVersion: 1,
            effectiveDate: DateTime.utc(2026, 1, 1),
          ),
        ],
      );

      final changed =
          getChangedLegalDocuments(acceptedVersion: 2, manifest: manifest);

      expect(changed, hasLength(1));
      expect(changed.single.kind, LegalDocumentKind.privacyPolicy);
    },
  );

  test('lists nothing when the accepted version already covers every document',
      () {
    final manifest = LegalManifest(
      currentVersion: 2,
      minAppVersion: '1.0.0',
      documents: [
        LegalManifestDocument(
          kind: LegalDocumentKind.privacyPolicy,
          url: 'https://example.com/privacy',
          changedInVersion: 2,
          effectiveDate: DateTime.utc(2026, 1, 1),
        ),
        LegalManifestDocument(
          kind: LegalDocumentKind.termsOfUse,
          url: 'https://example.com/terms',
          changedInVersion: 1,
          effectiveDate: DateTime.utc(2026, 1, 1),
        ),
      ],
    );

    final changed =
        getChangedLegalDocuments(acceptedVersion: 2, manifest: manifest);

    expect(changed, isEmpty);
  });
}
