import 'package:equatable/equatable.dart';

import 'legal_document.dart';
import 'legal_document_kind.dart';

/// One document's entry in the remote `legal.json` manifest
/// (`docs/legal/entrega-de-documentos-legales.md`).
///
/// [changedInVersion] is the joint legal-package version
/// ([LegalManifest.currentVersion]-shaped integer, not this document's own
/// semver-looking display string) in which this document's content last
/// changed. Comparing it against the accepted version is how
/// `GetChangedLegalDocuments` decides whether THIS document belongs in the
/// re-acceptance sheet, without the manifest having to carry full history.
class LegalManifestDocument extends Equatable {
  const LegalManifestDocument({
    required this.kind,
    required this.url,
    required this.changedInVersion,
    required this.effectiveDate,
  });

  final LegalDocumentKind kind;

  /// Where to download this document's body from.
  final String url;

  final int changedInVersion;

  /// The date THIS document's content took effect, as declared by the
  /// manifest. Attributed to a resolved [LegalDocument] only when it came
  /// from the cache — a bundled fallback always carries
  /// [bundledLegalDocumentsEffectiveDate] instead, regardless of what the
  /// manifest currently declares.
  final DateTime effectiveDate;

  @override
  List<Object?> get props => [kind, url, changedInVersion, effectiveDate];
}

/// The legal manifest (`legal.json`), telling the app which is the current
/// joint legal-package version, which app versions it applies to, and where
/// to fetch each document's body.
///
/// [documents] always has exactly one entry per [LegalDocumentKind] — see
/// [documentFor].
class LegalManifest extends Equatable {
  const LegalManifest({
    required this.currentVersion,
    required this.minAppVersion,
    required this.documents,
  });

  /// The offline fallback: what the app "knows" before ever downloading a
  /// real manifest, built purely from the bundled assets
  /// (`lib/core/legal/assets/`). Its `minAppVersion` is `'0.0.0'` so it never
  /// itself triggers re-acceptance — only a genuinely downloaded manifest
  /// declaring a newer [currentVersion] does that.
  factory LegalManifest.bundledFallback() => LegalManifest(
        currentVersion: bundledLegalDocumentsVersion,
        minAppVersion: '0.0.0',
        documents: [
          for (final kind in LegalDocumentKind.values)
            LegalManifestDocument(
              kind: kind,
              url: '',
              changedInVersion: bundledLegalDocumentsVersion,
              effectiveDate: bundledLegalDocumentsEffectiveDate,
            ),
        ],
      );

  /// The joint legal-package version currently in effect.
  final int currentVersion;

  /// Semver (`'1.4.0'`) of the lowest installed app version this
  /// [currentVersion] applies to. See
  /// `docs/legal/entrega-de-documentos-legales.md`, "`minAppVersion`: no lo
  /// quites".
  final String minAppVersion;

  final List<LegalManifestDocument> documents;

  LegalManifestDocument documentFor(LegalDocumentKind kind) =>
      documents.firstWhere((doc) => doc.kind == kind);

  @override
  List<Object?> get props => [currentVersion, minAppVersion, documents];
}
