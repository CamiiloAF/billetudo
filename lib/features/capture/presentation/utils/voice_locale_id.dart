import 'dart:ui';

/// Builds the `localeId` the platform recognizer expects (`es_CO`, `en_US`)
/// out of the locales Flutter can actually see.
///
/// The language always comes from the **app's** locale, never the device's:
/// transcribing Spanish with an English model produces confident garbage,
/// which is worse than an honest "no está disponible" (HU-08).
///
/// The *region* is a different question. `AppLocalizations` resolves to plain
/// `es` / `en` (there are no per-country ARBs), and a bare `es` is not a
/// locale id any recognizer accepts. So the region is borrowed from the
/// device when the device speaks the same language — a Colombian phone in
/// Spanish dictates as `es_CO`, which is exactly the variant the amount
/// heuristic was written for. When the two languages disagree there is no
/// honest region to borrow and a neutral default is used instead.
abstract final class VoiceLocaleId {
  const VoiceLocaleId._();

  /// Neutral fallbacks, only used when the device is set to another language.
  static const Map<String, String> _defaultRegions = {
    'es': 'ES',
    'en': 'US',
  };

  static const String _fallbackRegion = 'US';

  static String resolve(Locale appLocale, Locale deviceLocale) {
    final language = appLocale.languageCode;
    final deviceRegion = deviceLocale.countryCode;
    final region = appLocale.countryCode ??
        (deviceLocale.languageCode == language && deviceRegion != null
            ? deviceRegion
            : _defaultRegions[language] ?? _fallbackRegion);
    return '${language}_$region';
  }
}
