import 'package:injectable/injectable.dart';

import '../../../../features/settings/data/datasources/app_settings_local_datasource.dart';
import '../../../error/result.dart';
import '../../domain/entities/legal_document.dart';
import '../../domain/entities/legal_document_kind.dart';
import '../../domain/entities/legal_manifest.dart';
import '../../domain/repositories/legal_documents_repository.dart';
import '../datasources/legal_documents_cache_datasource.dart';
import '../datasources/legal_manifest_remote_datasource.dart';

/// Orchestrates the remote datasource, the disk cache and the bundled
/// fallback, and delegates the actual acceptance write to
/// [AppSettingsLocalDatasource] — the same singleton row `markAiConsentAccepted`
/// writes to, so there is only one place in the codebase that touches
/// `AppSettings`.
@LazySingleton(as: LegalDocumentsRepository)
class LegalDocumentsRepositoryImpl implements LegalDocumentsRepository {
  const LegalDocumentsRepositoryImpl(
    this._remote,
    this._cache,
    this._appSettings,
  );

  final LegalManifestRemoteDatasource _remote;
  final LegalDocumentsCacheDatasource _cache;
  final AppSettingsLocalDatasource _appSettings;

  @override
  FutureResult<LegalManifest> getManifest() async {
    try {
      final manifest = await _cache.readCachedManifest();
      return Right(manifest ?? LegalManifest.bundledFallback());
    } catch (e, st) {
      return Left(
        UnexpectedFailure(
          'failed to read legal manifest',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  FutureResult<LegalDocument> resolveDocument(LegalDocumentKind kind) async {
    try {
      final cachedManifest = await _cache.readCachedManifest();
      final manifest = cachedManifest ?? LegalManifest.bundledFallback();
      return Right(await _cache.resolveDocument(kind, manifest));
    } catch (e, st) {
      return Left(
        UnexpectedFailure(
          'failed to resolve legal document',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<void> refreshFromRemote() async {
    final fetchedManifest = await _remote.fetchManifest();
    // No connectivity, timeout, or a malformed response: keep whatever is
    // already cached/bundled and try again on a later launch — see
    // `docs/legal/entrega-de-documentos-legales.md`, "Una descarga legal
    // fallida no bloquea el arranque".
    if (fetchedManifest == null) {
      return;
    }
    final currentManifest =
        (await _cache.readCachedManifest()) ?? LegalManifest.bundledFallback();

    final resolvedDocuments = <LegalManifestDocument>[];
    for (final kind in LegalDocumentKind.values) {
      final fetchedDocument = fetchedManifest.documentFor(kind);
      final currentDocument = currentManifest.documentFor(kind);
      final hasNewerContent =
          fetchedDocument.changedInVersion > currentDocument.changedInVersion;
      if (!hasNewerContent) {
        resolvedDocuments.add(currentDocument);
        continue;
      }
      final body = await _remote.fetchDocumentBody(fetchedDocument.url);
      if (body == null) {
        // The manifest downloaded fine but this document's body did not:
        // keep serving the last version whose body we actually have, and
        // never claim the new one is available — see "Nunca pidas aceptar
        // un documento que no puedes mostrar".
        resolvedDocuments.add(currentDocument);
        continue;
      }
      await _cache.writeCachedDocument(kind, body);
      resolvedDocuments.add(fetchedDocument);
    }

    // The joint version in effect is the highest version whose body is
    // ACTUALLY cached, never the manifest's declared `currentVersion` when
    // that outran what could be downloaded — this is what makes
    // `ShouldShowReacceptance` and `GetChangedLegalDocuments` correct without
    // any extra logic on their side.
    final effectiveVersion = resolvedDocuments
        .map((doc) => doc.changedInVersion)
        .reduce((a, b) => a > b ? a : b);

    await _cache.writeCachedManifest(
      LegalManifest(
        currentVersion: effectiveVersion,
        minAppVersion: fetchedManifest.minAppVersion,
        documents: resolvedDocuments,
      ),
    );
  }

  @override
  FutureResult<Unit> acceptLegalDocuments({
    required int version,
    required DateTime acceptedAt,
  }) async {
    try {
      await _appSettings.markLegalAccepted(now: acceptedAt, version: version);
      return const Right(unit);
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'failed to record legal acceptance',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  FutureResult<int> getAcceptedVersion() async {
    try {
      final row = await _appSettings.readSettings();
      // `NULL` reads as `0` (never backfilled), same convention as
      // `AppSettings.aiConsentVersion` — see its doc comment in
      // `app_database.dart`.
      return Right(row?.legalAcceptedVersion ?? 0);
    } catch (e, st) {
      return Left(
        DatabaseFailure(
          'failed to read accepted legal version',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
