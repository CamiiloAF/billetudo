import 'package:injectable/injectable.dart';

/// HU-02 (`docs/requirements/fase-1/13-onboarding.md`): picks the currency to
/// pre-fill on the first-account step.
///
/// The requirements document originally asked for this to derive the
/// currency from the device locale's region (CO→COP, MX→MXN, AR→ARS,
/// CL→CLP, PE→PEN, ES→EUR, US→USD…), narrowed to what the Accounts currency
/// picker actually supports today (`COP`/`USD` only —
/// `AccountFormState.supportedCurrencies`, `currency_picker_sheet.dart`).
/// **Changed 2026-07-30:** region-based resolution was dropped entirely.
/// The device locale's region is a language/formatting preference, not the
/// user's real location — confirmed in testing with a device set to
/// Spanish (Spain) and later to a system region of `US` while physically in
/// Colombia, both of which resolved away from `COP`. `regionCode` is now
/// ignored: the app's primary market is Colombia, so the default is always
/// `COP`. The currency **always stays editable** here, so this is a starting
/// point, never a silent lock-in. Revisit once Accounts' currency picker
/// grows back the other currencies and/or a more reliable location signal
/// is worth the added complexity.
@injectable
class ResolveDefaultCurrencyForLocale {
  const ResolveDefaultCurrencyForLocale();

  static const String _cop = 'COP';

  /// [regionCode] is unused (kept for call-site compatibility) — see the
  /// class doc for why region-based resolution was dropped.
  String call(String? regionCode) => _cop;
}
