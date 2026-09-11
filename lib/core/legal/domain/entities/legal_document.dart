import 'package:equatable/equatable.dart';

import 'legal_document_kind.dart';

/// Where a resolved [LegalDocument]'s content actually came from. Never
/// surfaced as an error state — see
/// `docs/legal/entrega-de-documentos-legales.md`, "Ver el fallback no es un
/// error y no se presenta como tal."
enum LegalDocumentSource {
  /// Downloaded from the remote manifest and cached on disk.
  cache,

  /// The offline fallback shipped in `lib/core/legal/assets/`.
  bundle,
}

/// The joint legal-package version every bundled document ships with,
/// **bumped by hand in the same change that refreshes
/// `lib/core/legal/assets/*.md`** from `docs/legal/`. Never a placeholder.
///
/// One shared constant, not one per document, because acceptance is joint
/// (`docs/legal/entrega-de-documentos-legales.md`, "Lo que no cambia": "un
/// solo botón 'Acepto', una sola versión guardada. No se versiona por
/// documento.") — the two bundled `.md` files are always refreshed together
/// at release time, so they always share one version.
const int bundledLegalDocumentsVersion = 1;

/// The date the bundled documents took effect, alongside
/// [bundledLegalDocumentsVersion]. Update by hand together with the assets.
final DateTime bundledLegalDocumentsEffectiveDate = DateTime.utc(2026, 9, 3);

/// A legal document ready to show: resolved content plus the version/date
/// that content actually represents.
///
/// [legalVersion] and [effectiveDate] describe the CONTENT in [content], not
/// necessarily the remote manifest's declared current version — when
/// [source] is [LegalDocumentSource.bundle] (or a stale cache entry), they
/// can lag behind. That is by design: "La línea de versión y fecha del
/// visor refleja el documento que se está mostrando, no la versión vigente
/// del manifiesto" (`docs/legal/entrega-de-documentos-legales.md`).
class LegalDocument extends Equatable {
  const LegalDocument({
    required this.kind,
    required this.content,
    required this.legalVersion,
    required this.effectiveDate,
    required this.source,
  });

  final LegalDocumentKind kind;

  /// Markdown/plain text of the document, ready to render.
  final String content;

  /// The joint legal-package version this content belongs to — the same
  /// integer persisted in `AppSettings.legalAcceptedVersion` when this
  /// document is one of the ones accepted.
  final int legalVersion;

  final DateTime effectiveDate;

  final LegalDocumentSource source;

  @override
  List<Object?> get props =>
      [kind, content, legalVersion, effectiveDate, source];
}
