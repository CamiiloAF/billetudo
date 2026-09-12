import '../../../error/result.dart';
import '../entities/legal_document.dart';
import '../entities/legal_document_kind.dart';
import '../entities/legal_manifest.dart';

/// Contract for reading the legal manifest/documents (cache-first, bundle
/// fallback) and persisting joint acceptance.
///
/// Implemented in `data/` over an HTTP client, a disk cache and the shared
/// `AppSettings` singleton (`lib/features/settings/`). See
/// `docs/legal/entrega-de-documentos-legales.md` for the rules every method
/// here must respect.
abstract class LegalDocumentsRepository {
  /// The manifest known right now, without ever touching the network: the
  /// cached copy of the last successful download, or
  /// [LegalManifest.bundledFallback] when none exists yet. Never blocks and
  /// never fails on a missing/incomplete cache.
  FutureResult<LegalManifest> getManifest();

  /// The document to show right now for [kind]: the cached body if one was
  /// downloaded, otherwise the bundled asset. Never blocks on the network
  /// and never returns a loading/error/empty state — see
  /// `LegalDocumentSource`.
  FutureResult<LegalDocument> resolveDocument(LegalDocumentKind kind);

  /// Attempts, in the background, to download `legal.json` and any document
  /// body it references, updating the on-disk cache on success.
  ///
  /// Swallows every network failure silently (`docs/legal/…`, "Una descarga
  /// legal fallida no bloquea el arranque"): callers never need to branch on
  /// its result, they just call it and move on, and the next successful
  /// call is what eventually surfaces a newer version. A document whose body
  /// fails to download leaves that document's cache entry untouched, so
  /// `getManifest`/`resolveDocument` keep reporting the last version that
  /// was actually retrievable, never the higher one the manifest merely
  /// declared.
  Future<void> refreshFromRemote();

  /// Records joint acceptance of the legal terms: one row, one timestamp,
  /// stamped with [version] — the caller (`AcceptLegalDocuments`) has
  /// already reduced that to the version of what was truly shown, never the
  /// manifest's declared version if that differs.
  FutureResult<Unit> acceptLegalDocuments({
    required int version,
    required DateTime acceptedAt,
  });

  /// The joint version last accepted on this installation (`0` = never, or
  /// accepted before this column existed — see
  /// `AppSettings.legalAcceptedVersion`'s doc comment in
  /// `app_database.dart`).
  FutureResult<int> getAcceptedVersion();
}
