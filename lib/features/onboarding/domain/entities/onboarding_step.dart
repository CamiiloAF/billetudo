/// The four screens of the welcome flow, in the order defined by
/// `docs/requirements/13-onboarding.md` ("Secuencia real del flujo"). The
/// numbering is stable and historical (HU-01, HU-02, HU-07, HU-04) but the
/// screen order follows this enum's declaration order.
enum OnboardingStep {
  /// HU-01: the promise ("Nivel 0 completo y gratis"), with the secondary
  /// "Ya tengo cuenta" link (HU-06).
  welcome,

  /// HU-02: the first account, pre-filled and skippable.
  account,

  /// HU-07: explains cloud backup; skipped entirely if the user already
  /// authenticated via "Ya tengo cuenta" on [welcome] (HU-07's "no repetir el
  /// mensaje tres veces").
  backup,

  /// HU-04: the closing screen, inviting the first transaction (or, if the
  /// account step was skipped, bridging to `15-gate-cuenta.md`'s create-account
  /// prompt). Acting on this screen — registering or skipping — is what turns
  /// the `onboardingCompleted` latch on.
  closing,
}
