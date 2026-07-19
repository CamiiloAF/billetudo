import 'dart:ui';

import 'gen/app_localizations.dart';

/// Resolves which of the app's supported locales (`es`/`en`,
/// [AppLocalizations.supportedLocales]) best matches the device's language
/// preferences. Needed for code that must pick a language before the widget
/// tree exists — e.g. `bootstrap.dart`/HU-06 category seeding
/// (`docs/requirements/05-auth-sync.md`, decision #12): it has no
/// `BuildContext` to read `Localizations.localeOf`, but should still land on
/// a sensible language.
///
/// The match step (exact/language-only against the device's preferred
/// locales, in order) mirrors Flutter's default `basicLocaleListResolution`
/// (the algorithm `WidgetsApp`/`MaterialApp` use with no custom
/// `localeListResolutionCallback`, which is this app's case — see
/// `app.dart`). The **fallback** deliberately does not: `es`, not
/// `supportedLocales.first`. `supportedLocales.first` happens to be `en`
/// today only because `flutter gen-l10n` orders that list alphabetically by
/// the `.arb` files it finds (`app_en.arb` before `app_es.arb`) — an
/// accident of generation, not a product decision. `es` is this app's real
/// default: `l10n.yaml`'s `template-arb-file` is `app_es.arb`, `app.dart`
/// documents "es as the natural fallback", and CLAUDE.md scopes the whole
/// app to "el mercado hispanohablante". Hardcoding `es` here keeps HU-06
/// seeding in Spanish for a device whose locale is neither `es` nor `en`
/// (e.g. `pt_BR`), instead of silently defaulting to English.
abstract final class AppLocale {
  static const String fallbackLanguageCode = 'es';

  /// [preferredLocales] defaults to `PlatformDispatcher.instance.locales`
  /// (the real device preferences) — overridable so tests can pick a
  /// language deterministically without depending on ambient OS/test-runner
  /// locale state, which `dart:ui`'s `PlatformDispatcher.instance` singleton
  /// otherwise has no supported way to fake outside a widget test.
  static String resolveLanguageCode({List<Locale>? preferredLocales}) {
    final supportedLanguageCodes = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();

    final preferred =
        preferredLocales ?? PlatformDispatcher.instance.locales;
    for (final locale in preferred) {
      if (supportedLanguageCodes.contains(locale.languageCode)) {
        return locale.languageCode;
      }
    }

    return fallbackLanguageCode;
  }
}
