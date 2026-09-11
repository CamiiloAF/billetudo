import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../domain/entities/legal_document_kind.dart';
import '../../domain/entities/legal_manifest.dart';

/// The published URL of `legal.json` (GitHub Pages, `web/README.md`).
///
/// Short-cached/cache-busted at the CDN on purpose — see
/// `docs/legal/entrega-de-documentos-legales.md`, "Caché del CDN": a legal
/// fix has to reach devices without waiting out an hours-long cache.
const String legalManifestUrl =
    'https://camiiloaf.github.io/billetudo/legal.json';

/// Downloads `legal.json` over HTTP.
///
/// Deliberately has **no** disk cache of its own — that lives in
/// `LegalDocumentsCacheDatasource`. This class only knows how to ask the
/// network and never throws for an expected network failure: every method
/// returns `null` instead, matching
/// `docs/legal/entrega-de-documentos-legales.md`'s "una descarga legal
/// fallida no bloquea el arranque" — there is nothing for a caller to catch,
/// only a value to check.
@lazySingleton
class LegalManifestRemoteDatasource {
  LegalManifestRemoteDatasource() : _client = http.Client();

  /// Injects a test client. The production constructor takes no arguments on
  /// purpose: a plain `http.Client()` is not a container dependency, same
  /// convention as `IssuerRulesAssetDatasource.withBundle`.
  @visibleForTesting
  LegalManifestRemoteDatasource.withClient(http.Client client)
      : _client = client;

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 8);

  /// `null` on any network/parse failure (timeout, 4xx/5xx, malformed JSON,
  /// unexpected shape) — never throws.
  Future<LegalManifest?> fetchManifest() async {
    try {
      final response =
          await _client.get(Uri.parse(legalManifestUrl)).timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return _parse(response.body);
    } on Object {
      return null;
    }
  }

  /// `null` on any network failure. Never throws.
  Future<String?> fetchDocumentBody(String url) async {
    if (url.isEmpty) {
      return null;
    }
    try {
      final response = await _client.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return response.body;
    } on Object {
      return null;
    }
  }

  LegalManifest? _parse(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      final currentVersion = json['currentVersion'];
      final minAppVersion = json['minAppVersion'];
      final rawDocuments = json['documents'];
      if (currentVersion is! int ||
          minAppVersion is! String ||
          rawDocuments is! List) {
        return null;
      }
      final documents = <LegalManifestDocument>[];
      for (final rawDocument in rawDocuments) {
        if (rawDocument is! Map<String, dynamic>) {
          return null;
        }
        final kind = _parseKind(rawDocument['kind']);
        final url = rawDocument['url'];
        final changedInVersion = rawDocument['changedInVersion'];
        final effectiveDate = _parseDate(rawDocument['effectiveDate']);
        if (kind == null ||
            url is! String ||
            changedInVersion is! int ||
            effectiveDate == null) {
          return null;
        }
        documents.add(
          LegalManifestDocument(
            kind: kind,
            url: url,
            changedInVersion: changedInVersion,
            effectiveDate: effectiveDate,
          ),
        );
      }
      // Missing an entry for either known document makes the manifest
      // unusable — `LegalManifest.documentFor` would throw downstream.
      for (final kind in LegalDocumentKind.values) {
        if (!documents.any((doc) => doc.kind == kind)) {
          return null;
        }
      }
      return LegalManifest(
        currentVersion: currentVersion,
        minAppVersion: minAppVersion,
        documents: documents,
      );
    } on Object {
      return null;
    }
  }

  DateTime? _parseDate(Object? raw) {
    if (raw is! String) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  LegalDocumentKind? _parseKind(Object? raw) {
    if (raw is! String) {
      return null;
    }
    for (final kind in LegalDocumentKind.values) {
      if (kind.name == raw) {
        return kind;
      }
    }
    return null;
  }
}
