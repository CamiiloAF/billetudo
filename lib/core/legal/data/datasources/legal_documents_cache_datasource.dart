import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/legal_document.dart';
import '../../domain/entities/legal_document_kind.dart';
import '../../domain/entities/legal_manifest.dart';

/// Where the on-disk cache of the manifest and document bodies lives.
///
/// Behind an interface only so tests can point at a temp directory:
/// `path_provider` has no platform channel implementation under
/// `flutter test` — same reasoning as `SyncStorageDirectory`.
abstract class LegalCacheDirectory {
  Future<Directory> resolve();
}

/// Production implementation: `<app documents>/legal/`.
@LazySingleton(as: LegalCacheDirectory)
class AppDocumentsLegalCacheDirectory implements LegalCacheDirectory {
  const AppDocumentsLegalCacheDirectory();

  @override
  Future<Directory> resolve() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'legal'));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}

/// Reads/writes the cached manifest and document bodies on disk, and falls
/// back to the bundled assets (`lib/core/legal/assets/`) when no cache entry
/// exists yet.
///
/// Every read here is synchronous with respect to the network — it never
/// waits on a download, matching
/// `docs/legal/entrega-de-documentos-legales.md`, "Lectura": "El visor lee
/// del caché en disco y, si no hay, del documento empaquetado en la app.
/// Nunca espera a la red."
@lazySingleton
class LegalDocumentsCacheDatasource {
  LegalDocumentsCacheDatasource(this._directory) : _bundle = rootBundle;

  /// Injects a test bundle/directory. The production constructor takes no
  /// `bundle` argument on purpose: `rootBundle` is not a container
  /// dependency, same convention as `IssuerRulesAssetDatasource.withBundle`.
  @visibleForTesting
  LegalDocumentsCacheDatasource.withBundle(
    this._directory, {
    required AssetBundle bundle,
  }) : _bundle = bundle;

  static const Map<LegalDocumentKind, String> _bundledAssetPaths = {
    LegalDocumentKind.privacyPolicy:
        'lib/core/legal/assets/politica-de-privacidad.md',
    LegalDocumentKind.termsOfUse: 'lib/core/legal/assets/terminos-de-uso.md',
  };

  static const String _manifestFileName = 'legal_manifest.json';

  final LegalCacheDirectory _directory;
  final AssetBundle _bundle;

  Future<LegalManifest?> readCachedManifest() async {
    final file = await _manifestFile();
    if (!file.existsSync()) {
      return null;
    }
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) {
        return null;
      }
      final rawDocuments = json['documents'];
      if (rawDocuments is! List) {
        return null;
      }
      return LegalManifest(
        currentVersion: json['currentVersion'] as int,
        minAppVersion: json['minAppVersion'] as String,
        documents: [
          for (final rawDocument in rawDocuments.cast<Map<String, dynamic>>())
            LegalManifestDocument(
              kind: LegalDocumentKind.values
                  .firstWhere((kind) => kind.name == rawDocument['kind']),
              url: rawDocument['url'] as String,
              changedInVersion: rawDocument['changedInVersion'] as int,
              effectiveDate:
                  DateTime.parse(rawDocument['effectiveDate'] as String),
            ),
        ],
      );
    } on Object {
      // A corrupt cache file behaves exactly like a missing one: fall back,
      // never crash the caller.
      return null;
    }
  }

  Future<void> writeCachedManifest(LegalManifest manifest) async {
    final file = await _manifestFile();
    final json = {
      'currentVersion': manifest.currentVersion,
      'minAppVersion': manifest.minAppVersion,
      'documents': [
        for (final document in manifest.documents)
          {
            'kind': document.kind.name,
            'url': document.url,
            'changedInVersion': document.changedInVersion,
            'effectiveDate': document.effectiveDate.toIso8601String(),
          },
      ],
    };
    await file.writeAsString(jsonEncode(json));
  }

  /// The document to show right now for [kind]: the cached body if one was
  /// downloaded, otherwise the bundled fallback asset. [manifest] supplies
  /// the version/date to attribute to a CACHED body — a bundled fallback
  /// always carries [bundledLegalDocumentsVersion] instead, regardless of
  /// what the manifest currently declares.
  Future<LegalDocument> resolveDocument(
    LegalDocumentKind kind,
    LegalManifest manifest,
  ) async {
    final cacheFile = await _documentFile(kind);
    if (cacheFile.existsSync()) {
      final content = await cacheFile.readAsString();
      final manifestDocument = manifest.documentFor(kind);
      return LegalDocument(
        kind: kind,
        content: content,
        legalVersion: manifestDocument.changedInVersion,
        effectiveDate: manifestDocument.effectiveDate,
        source: LegalDocumentSource.cache,
      );
    }
    return _readBundledDocument(kind);
  }

  Future<void> writeCachedDocument(
      LegalDocumentKind kind, String content) async {
    final file = await _documentFile(kind);
    await file.writeAsString(content);
  }

  Future<LegalDocument> _readBundledDocument(LegalDocumentKind kind) async {
    final content = await _bundle.loadString(_bundledAssetPaths[kind]!);
    return LegalDocument(
      kind: kind,
      content: content,
      legalVersion: bundledLegalDocumentsVersion,
      effectiveDate: bundledLegalDocumentsEffectiveDate,
      source: LegalDocumentSource.bundle,
    );
  }

  Future<File> _manifestFile() async {
    final directory = await _directory.resolve();
    return File(p.join(directory.path, _manifestFileName));
  }

  Future<File> _documentFile(LegalDocumentKind kind) async {
    final directory = await _directory.resolve();
    return File(p.join(directory.path, '${kind.name}.md'));
  }
}
