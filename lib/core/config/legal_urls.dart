/// The public legal pages Ajustes links to, served by GitHub Pages from the
/// `gh-pages` branch (the built output of `web/dist/`, generated from
/// `docs/legal/` — see `web/README.md`, published 2026-08-18).
///
/// These same two URLs are the ones declared in the Play Console and App Store
/// Connect listings, so they must stay in sync with `web/README.md`: changing
/// one without the other leaves the app pointing at a 404 while the stores
/// keep the old address.
abstract final class LegalUrls {
  /// `docs/legal/politica-de-privacidad.md`.
  static final Uri privacyPolicy =
      Uri.parse('https://camiiloaf.github.io/billetudo/');

  /// `docs/legal/terminos-de-uso.md`.
  static final Uri termsOfUse =
      Uri.parse('https://camiiloaf.github.io/billetudo/terminos.html');
}
