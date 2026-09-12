import 'package:injectable/injectable.dart';

import '../entities/legal_manifest.dart';

/// The documents whose content changed since `acceptedVersion`, compared
/// against the current manifest.
///
/// The re-acceptance sheet lists **only** these — one row and singular copy
/// when only one document changed
/// (`docs/legal/entrega-de-documentos-legales.md`, "Lo que no cambia").
@lazySingleton
class GetChangedLegalDocuments {
  const GetChangedLegalDocuments();

  List<LegalManifestDocument> call({
    required int acceptedVersion,
    required LegalManifest manifest,
  }) =>
      manifest.documents
          .where((doc) => doc.changedInVersion > acceptedVersion)
          .toList(growable: false);
}
