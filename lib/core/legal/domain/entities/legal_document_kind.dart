/// The two legal documents billetudo requires acceptance of. Parametrizes
/// the manifest, the viewer and the acceptance/re-acceptance sheets so none
/// of them hardcode a document by name.
enum LegalDocumentKind {
  /// `docs/legal/politica-de-privacidad.md`.
  privacyPolicy,

  /// `docs/legal/terminos-de-uso.md`.
  termsOfUse,
}
