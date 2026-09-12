/// The version of the AI assistant's data-sharing consent copy that this
/// build ships (`AppSettings.aiConsentVersion` in `app_database.dart`).
///
/// **Bump this BY HAND, in the same change that edits the consent copy**,
/// whenever the disclosure widens — a new field travelling to the model, a new
/// provider, a new retention rule. Consent only counts as granted when
/// `aiConsentAcceptedAt != null && aiConsentVersion >= currentAiConsentVersion`
/// (see `AppSettings.hasAcceptedAiConsent`), so bumping it is what re-shows the
/// consent screen to someone who accepted an older, narrower disclosure. Apple
/// 5.1.2(i) requires the consent to be *informed*; a stale acceptance is not.
///
/// History:
///  - `1` — the original copy, which stated that notes never leave the device.
///  - `2` — current. Adds the opt-in that can let the assistant read the
///    free-text `note` of the user's records (`AppSettings.aiNotesAccessEnabled`),
///    so the version-1 wording is no longer true and everyone is asked again.
///
/// Anyone who accepted before the column existed reads as `0` (the column is
/// nullable and never backfilled), which is below any current version and
/// therefore re-asks too.
const int currentAiConsentVersion = 2;
