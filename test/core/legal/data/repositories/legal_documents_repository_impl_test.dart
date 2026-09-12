import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/core/legal/data/datasources/legal_documents_cache_datasource.dart';
import 'package:billetudo/core/legal/data/datasources/legal_manifest_remote_datasource.dart';
import 'package:billetudo/core/legal/data/repositories/legal_documents_repository_impl.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/entities/legal_manifest.dart';
import 'package:billetudo/features/settings/data/datasources/app_settings_local_datasource.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fake_asset_bundle.dart';
import '../../support/temp_legal_cache_directory.dart';

class MockLegalManifestRemoteDatasource extends Mock
    implements LegalManifestRemoteDatasource {}

void main() {
  late db.AppDatabase database;
  late AppSettingsLocalDatasource appSettings;
  late TempLegalCacheDirectory directory;
  late LegalDocumentsCacheDatasource cache;
  late MockLegalManifestRemoteDatasource remote;
  late LegalDocumentsRepositoryImpl repository;

  final bundle = FakeAssetBundle({
    'lib/core/legal/assets/politica-de-privacidad.md': '# Política (bundle)',
    'lib/core/legal/assets/terminos-de-uso.md': '# Términos (bundle)',
  });

  LegalManifest remoteManifest({
    required int privacyChangedInVersion,
    required int termsChangedInVersion,
    required int currentVersion,
  }) =>
      LegalManifest(
        currentVersion: currentVersion,
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
    database = db.AppDatabase(NativeDatabase.memory());
    appSettings = AppSettingsLocalDatasource(database);
    directory = TempLegalCacheDirectory.create();
    cache = LegalDocumentsCacheDatasource.withBundle(directory, bundle: bundle);
    remote = MockLegalManifestRemoteDatasource();
    repository = LegalDocumentsRepositoryImpl(remote, cache, appSettings);
  });

  tearDown(() async {
    await database.close();
    directory.dispose();
  });

  test('getManifest falls back to the bundle when nothing was ever cached',
      () async {
    final result = await repository.getManifest();

    expect(result.isRight(), isTrue);
    final manifest =
        result.getOrElse((_) => throw StateError('expected Right'));
    expect(manifest, LegalManifest.bundledFallback());
  });

  group('refreshFromRemote', () {
    test(
      'a failed manifest download (connectivity present) never throws and '
      'leaves the cache untouched, so the next launch is unaffected',
      () async {
        when(remote.fetchManifest).thenAnswer((_) async => null);

        await repository.refreshFromRemote();

        expect(await cache.readCachedManifest(), isNull);
        verifyNever(() => remote.fetchDocumentBody(any()));
      },
    );

    test(
      'when both document bodies download fine, the cached manifest adopts '
      'the fetched currentVersion',
      () async {
        final fetched = remoteManifest(
          privacyChangedInVersion: 2,
          termsChangedInVersion: 2,
          currentVersion: 2,
        );
        when(remote.fetchManifest).thenAnswer((_) async => fetched);
        when(() => remote.fetchDocumentBody(any()))
            .thenAnswer((_) async => '# nuevo contenido');

        await repository.refreshFromRemote();

        final cached = await cache.readCachedManifest();
        expect(cached!.currentVersion, 2);
      },
    );

    test(
      'when the manifest downloads fine but one document body fails, that '
      'document is NOT advertised as changed and the overall version does '
      'not outrun what is actually available — "nunca pidas aceptar un '
      'documento que no puedes mostrar"',
      () async {
        final fetched = remoteManifest(
          privacyChangedInVersion: 2,
          termsChangedInVersion: 2,
          currentVersion: 2,
        );
        when(remote.fetchManifest).thenAnswer((_) async => fetched);
        when(
          () => remote.fetchDocumentBody('https://example.com/privacy.md'),
        ).thenAnswer((_) async => '# política nueva');
        when(
          () => remote.fetchDocumentBody('https://example.com/terms.md'),
        ).thenAnswer((_) async => null);

        await repository.refreshFromRemote();

        final cached = await cache.readCachedManifest();
        // The overall version stays at the privacy policy's new version
        // (2) — not lower, since that one truly is available now — but the
        // terms-of-use entry keeps its OLD changedInVersion because its body
        // never made it to the cache.
        expect(
          cached!.documentFor(LegalDocumentKind.privacyPolicy).changedInVersion,
          2,
        );
        expect(
          cached.documentFor(LegalDocumentKind.termsOfUse).changedInVersion,
          bundledLegalDocumentsVersion,
        );
        // Nothing was ever cached for terms of use, so resolving it still
        // falls back to the bundle.
        final termsDocument = await cache.resolveDocument(
          LegalDocumentKind.termsOfUse,
          cached,
        );
        expect(termsDocument.source, LegalDocumentSource.bundle);
      },
    );

    test(
      'does not re-download a document whose changedInVersion has not moved',
      () async {
        await cache.writeCachedManifest(
          remoteManifest(
            privacyChangedInVersion: 2,
            termsChangedInVersion: 2,
            currentVersion: 2,
          ),
        );
        final fetched = remoteManifest(
          privacyChangedInVersion: 2,
          termsChangedInVersion: 2,
          currentVersion: 2,
        );
        when(remote.fetchManifest).thenAnswer((_) async => fetched);

        await repository.refreshFromRemote();

        verifyNever(() => remote.fetchDocumentBody(any()));
      },
    );
  });

  group('acceptLegalDocuments / getAcceptedVersion', () {
    test('round-trips through the shared AppSettings singleton', () async {
      expect(
        (await repository.getAcceptedVersion())
            .getOrElse((_) => throw StateError('expected Right')),
        0,
      );

      final acceptedAt = DateTime.now();
      final acceptResult = await repository.acceptLegalDocuments(
        version: 3,
        acceptedAt: acceptedAt,
      );

      expect(acceptResult.isRight(), isTrue);
      expect(
        (await repository.getAcceptedVersion())
            .getOrElse((_) => throw StateError('expected Right')),
        3,
      );
    });
  });
}
