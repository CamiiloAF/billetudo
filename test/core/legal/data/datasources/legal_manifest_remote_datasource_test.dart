import 'dart:convert';

import 'package:billetudo/core/legal/data/datasources/legal_manifest_remote_datasource.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const validManifestJson = '''
{
  "currentVersion": 2,
  "minAppVersion": "1.4.0",
  "documents": [
    {"kind": "privacyPolicy", "url": "https://example.com/privacy.md", "changedInVersion": 2, "effectiveDate": "2026-09-03T00:00:00.000Z"},
    {"kind": "termsOfUse", "url": "https://example.com/terms.md", "changedInVersion": 1, "effectiveDate": "2026-08-25T00:00:00.000Z"}
  ]
}
''';

  LegalManifestRemoteDatasource datasourceWith(
    http.Response Function(http.Request) responder,
  ) =>
      LegalManifestRemoteDatasource.withClient(
        MockClient((request) async => responder(request)),
      );

  group('fetchManifest', () {
    test('parses a well-formed manifest', () async {
      final datasource =
          datasourceWith((request) => http.Response(validManifestJson, 200));

      final manifest = await datasource.fetchManifest();

      expect(manifest, isNotNull);
      expect(manifest!.currentVersion, 2);
      expect(manifest.minAppVersion, '1.4.0');
      expect(
        manifest.documentFor(LegalDocumentKind.privacyPolicy).changedInVersion,
        2,
      );
      expect(
        manifest.documentFor(LegalDocumentKind.termsOfUse).changedInVersion,
        1,
      );
    });

    test(
      'a failed download (with connectivity) never throws — it returns null '
      'so the app never blocks the launch on it',
      () async {
        final datasource =
            datasourceWith((request) => http.Response('not found', 404));

        final manifest = await datasource.fetchManifest();

        expect(manifest, isNull);
      },
    );

    test('malformed JSON returns null instead of throwing', () async {
      final datasource =
          datasourceWith((request) => http.Response('not json at all', 200));

      final manifest = await datasource.fetchManifest();

      expect(manifest, isNull);
    });

    test('a manifest missing one of the two known documents returns null',
        () async {
      final incomplete = jsonEncode({
        'currentVersion': 2,
        'minAppVersion': '1.0.0',
        'documents': [
          {
            'kind': 'privacyPolicy',
            'url': 'https://example.com/privacy.md',
            'changedInVersion': 2,
            'effectiveDate': '2026-09-03T00:00:00.000Z',
          },
        ],
      });
      final datasource =
          datasourceWith((request) => http.Response(incomplete, 200));

      final manifest = await datasource.fetchManifest();

      expect(manifest, isNull);
    });

    test('a client exception (no connectivity) returns null, never throws',
        () async {
      final datasource = LegalManifestRemoteDatasource.withClient(
        MockClient((request) => throw http.ClientException('offline')),
      );

      final manifest = await datasource.fetchManifest();

      expect(manifest, isNull);
    });
  });

  group('fetchDocumentBody', () {
    test('returns the body on a successful download', () async {
      final datasource =
          datasourceWith((request) => http.Response('# Hola', 200));

      final body = await datasource.fetchDocumentBody('https://example.com/x');

      expect(body, '# Hola');
    });

    test('returns null on a failed download instead of throwing', () async {
      final datasource =
          datasourceWith((request) => http.Response('gone', 500));

      final body = await datasource.fetchDocumentBody('https://example.com/x');

      expect(body, isNull);
    });

    test('returns null for an empty url without touching the network',
        () async {
      var called = false;
      final datasource = datasourceWith((request) {
        called = true;
        return http.Response('', 200);
      });

      final body = await datasource.fetchDocumentBody('');

      expect(body, isNull);
      expect(called, isFalse);
    });
  });
}
