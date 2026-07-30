import 'package:injectable/injectable.dart';

/// HU-02 (`docs/requirements/13-onboarding.md`): picks the currency to
/// pre-fill on the first-account step, from the device locale's region.
///
/// The requirements document lists a wider table (CO→COP, MX→MXN, AR→ARS,
/// CL→CLP, PE→PEN, ES→EUR, US→USD…), but the Accounts currency picker
/// (`AccountFormState.supportedCurrencies`,
/// `currency_picker_sheet.dart`) deliberately only offers `COP` and `USD`
/// today — MXN/ARS/CLP/PEN/EUR were retired from it on purpose. Pre-filling a
/// currency the picker cannot actually offer would show the user a value they
/// then cannot keep, so this use case narrows the table to what the picker
/// supports: `CO` resolves to `COP`, everything else (including an unknown or
/// missing region) falls back to `USD`. Widen this once Accounts' currency
/// picker grows back the other currencies.
@injectable
class ResolveDefaultCurrencyForLocale {
  const ResolveDefaultCurrencyForLocale();

  static const String _cop = 'COP';
  static const String _usd = 'USD';

  /// [regionCode] is an ISO 3166-1 alpha-2 region (e.g. the `countryCode` of
  /// the device's `Locale`, or `Platform.localeName`'s region segment).
  /// `null` or unrecognized values fall back to [_usd].
  String call(String? regionCode) {
    if (regionCode == null) {
      return _usd;
    }
    return regionCode.toUpperCase() == 'CO' ? _cop : _usd;
  }
}
