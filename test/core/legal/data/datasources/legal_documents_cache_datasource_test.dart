import 'package:billetudo/core/legal/data/datasources/legal_documents_cache_datasource.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/entities/legal_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_asset_bundle.dart';
import '../../support/temp_legal_cache_directory.dart';

void main() {
  late TempLegalCacheDirectory directory;
  late LegalDocumentsCacheDatasource datasource;

  final bundle = FakeAssetBundle({
    'lib/core/legal/assets/politica-de-privacidad.md': '# Política (bundle)',
    'lib/core/legal/assets/terminos-de-uso.md': '# Términos (bundle)',
  });

  LegalManifest manifestWith({
    required int privacyChangedInVersion,
    required int termsChangedInVersion,
  }) =>
      LegalManifest(
        currentVersion: 5,
        minAppVersion: '1.0.0',
        documents: [
          LegalManifestDocument(
            kind: LegalDocumentKind.privacyPolicy,
            url: 'https://example.com/privacy.md',
            changedInVersion: privacyChangedInVersion,
            effectiveDate: DateTime.utc(2026, 9, 1),
          ),
          LegalManifestDocument(
            kind: LegalDocumentKind.termsOfUse,
            url: 'https://example.com/terms.md',
            changedInVersion: termsChangedInVersion,
            effectiveDate: DateTime.utc(2026, 8, 1),
          ),
        ],
      );

  setUp(() {
    directory = TempLegalCacheDirectory.create();
    datasource = LegalDocumentsCacheDatasource.withBundle(
      directory,
      bundle: bundle,
    );
  });

  tearDown(() => directory.dispose());

  group('manifest cache', () {
    test('reading before ever writing returns null', () async {
      expect(await datasource.readCachedManifest(), isNull);
    });

    test('round-trips a written manifest exactly', () async {
      final manifest = manifestWith(
        privacyChangedInVersion: 2,
        termsChangedInVersion: 1,
      );

      await datasource.writeCachedManifest(manifest);
      final read = await datasource.readCachedManifest();

      expect(read, manifest);
    });
  });

  group('resolveDocument', () {
    test('falls back to the bundled asset when nothing is cached yet',
        () async {
      final manifest = manifestWith(
        privacyChangedInVersion: 5,
        termsChangedInVersion: 5,
      );

      final document = await datasource.resolveDocument(
        LegalDocumentKind.privacyPolicy,
        manifest,
      );

      expect(document.content, '# Política (bundle)');
      expect(document.source, LegalDocumentSource.bundle);
      expect(document.legalVersion, bundledLegalDocumentsVersion);
      expect(document.effectiveDate, bundledLegalDocumentsEffectiveDate);
    });

    test(
      'reads the cached body and attributes it to the manifest\'s version '
      'for that document — never the bundle\'s',
      () async {
        await datasource.writeCachedDocument(
          LegalDocumentKind.termsOfUse,
          '# Términos (descargados)',
        );
        final manifest = manifestWith(
          privacyChangedInVersion: 5,
          termsChangedInVersion: 4,
        );

        final document = await datasource.resolveDocument(
          LegalDocumentKind.termsOfUse,
          manifest,
        );

        expect(document.content, '# Términos (descargados)');
        expect(document.source, LegalDocumentSource.cache);
        expect(document.legalVersion, 4);
      },
    );
  });
}
