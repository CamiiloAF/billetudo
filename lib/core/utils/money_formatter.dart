import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

/// Formats and parses amounts. **Project golden rule:** money is ALWAYS stored
/// as integers in minor units (cents); never `double`. This helper is the only
/// place that converts between that representation and the text the user sees.
///
/// Multi-currency note: for now the minor unit is assumed to be 1/100 (cents),
/// consistent with the storage convention. Reconciling currencies with a
/// different number of decimals is defined in `12-multi-moneda.md`.
///
/// **Locale follow-up (bilingual — pending, app-wide).** [format] and
/// [formatAmount] default to the `es_CO` grouping/decimals (`$1.234,56`), but
/// the app now follows the device locale (es/en — see `app.dart`, which no
/// longer pins `es-CO`). So on an English device the amount still renders in
/// es-CO style under English UI. Making the *display* formatting follow the
/// active locale (`Localizations.localeOf(context).toString()`, same fix the
/// Home dates already got) is a pending change that touches every caller
/// (Transacciones, Cuentas and Inicio). Parsing (`parseScaled`) intentionally
/// stays es-CO: it matches the numeric-keypad input convention, not the display
/// locale, so it is out of scope for this follow-up.
@lazySingleton
class MoneyFormatter {
  const MoneyFormatter();

  static const int _minorPerMajor = 100;

  /// How many decimals the *stored* minor unit carries, for every currency.
  /// Paired with [_minorPerMajor]; only [currencyDecimals] varies.
  static const int _storedDecimals = 2;

  /// The leading symbol [formatSymbol] prepends. Exposed so an *editable*
  /// amount field can paint it as a fixed prefix outside the editable text
  /// (where it would otherwise be stripped by the field's digit-only input
  /// formatter), and still read exactly like the read-only `$45.000` the
  /// design shows.
  static const String currencySymbol = r'$';

  /// How many decimals a currency shows to the user. Storage always keeps two
  /// (minor unit = 1/100, see [_minorPerMajor]); this is only about *display*.
  /// COP has no cents in practice, so it reads as a whole number (`$45.000`),
  /// while USD keeps its two (`$12.34`). The full app-wide reconciliation of
  /// per-currency minor units lives in `12-multi-moneda.md`; this covers the
  /// two currencies the app handles today.
  static int currencyDecimals(String currencyCode) =>
      currencyCode == 'COP' ? 0 : 2;

  /// `1234, currencyCode: 'COP'` → `"$1.234"` (per [locale]).
  ///
  /// [decimalDigits] overrides how many decimals are shown; when omitted the
  /// currency's own default applies via [currencyDecimals] (COP `$1.234`, USD
  /// `$12,34`). Note that intl's own default for the `COP` currency code is two
  /// decimals, so relying on it would render `,00`; that is why the default is
  /// pinned to [currencyDecimals] instead.
  String format(
    int amountMinor, {
    required String currencyCode,
    String locale = 'es_CO',
    int? decimalDigits,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      decimalDigits: decimalDigits ?? currencyDecimals(currencyCode),
    );
    return formatter.format(amountMinor / _minorPerMajor);
  }

  /// Like [format] but renders the `$` **symbol** instead of the currency code
  /// (`1234, 'COP'` → `"$1.234"`), and defaults to the currency's own decimals
  /// ([currencyDecimals]). Use it where the design shows a plain `$45.000`
  /// (e.g. the transaction form's Zona Fija) rather than the `COP` code.
  ///
  /// Builds the string manually (symbol + [formatAmount]) instead of letting
  /// `NumberFormat.currency` place the symbol: for `es_CO`, ICU's currency
  /// pattern puts the symbol *after* the number (`"1.234 $"`), which reads
  /// backwards for a `$`-prefixed design — Pencil always shows `$` leading.
  ///
  /// Display only — the amount never becomes a stored `double`, same as
  /// [format].
  String formatSymbol(
    int amountMinor, {
    required String currencyCode,
    String locale = 'es_CO',
    int? decimalDigits,
  }) {
    final digits = formatAmount(
      amountMinor,
      locale: locale,
      decimalDigits: decimalDigits ?? currencyDecimals(currencyCode),
    );
    return '$currencySymbol$digits';
  }

  /// Same as [format] but without the currency code/symbol (digits only).
  ///
  /// [decimalDigits] controls how many decimals are shown and defaults to two,
  /// which suits non-currency values like basis-point rates (`2450` → `24,50`).
  /// For money, pass the currency's own decimals via [currencyDecimals] so COP
  /// reads as a whole number (`4500000` → `45.000`) while USD keeps its cents.
  String formatAmount(
    int amountMinor, {
    String locale = 'es_CO',
    int? decimalDigits,
  }) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: decimalDigits ?? 2,
    );
    return formatter.format(amountMinor / _minorPerMajor);
  }

  /// Like [formatAmount] but **editable**: it never bakes in a thousands
  /// separator, only the decimal one (when [decimalDigits] > 0). Use it for the
  /// `initialValue` of a plain `TextFormField` the user is meant to keep
  /// typing in — `formatAmount`'s grouping dot lands inside the editable text
  /// and fights every edit after the first (e.g. reopening a saved credit
  /// limit). [format]/[formatAmount] stay the ones to use for read-only
  /// display, where the grouping helps instead of getting in the way.
  String formatAmountForEditing(
    int amountMinor, {
    String locale = 'es_CO',
    int? decimalDigits,
  }) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: decimalDigits ?? 2,
    )..turnOffGrouping();
    return formatter.format(amountMinor / _minorPerMajor);
  }

  /// Rounds [amountMinor] to the precision [currencyCode] actually shows.
  ///
  /// Storage always keeps 1/100 (see [_minorPerMajor]) whatever the currency,
  /// so switching currency never *reinterprets* a stored amount: `450000000`
  /// is 4.500.000,00 in COP and in USD alike. What does change is how many of
  /// those decimals are visible — COP shows none — and a field must not
  /// display `1.235` while it still holds `1.234,56`. This is what reconciles
  /// the two: the visible figure is also the stored one.
  ///
  /// Rounds **half-up on the magnitude**, the same rule [parseScaled] already
  /// applies to digits typed past the currency's precision. Truncating was the
  /// alternative and it is worse: it drops the user's cents silently *and*
  /// always downwards, so `1.234,99` would become `1.234`. Half-up moves the
  /// figure by at most half a unit and matches what the user was already
  /// reading. Going back to a currency with cents cannot restore them — they
  /// are gone at the moment the figure is shown without them.
  static int roundToCurrencyPrecision(int amountMinor, String currencyCode) {
    final factor = _pow10(_storedDecimals - currencyDecimals(currencyCode));
    if (factor <= 1) {
      return amountMinor;
    }
    final negative = amountMinor < 0;
    final magnitude = negative ? -amountMinor : amountMinor;
    final rounded = ((magnitude + factor ~/ 2) ~/ factor) * factor;
    return negative ? -rounded : rounded;
  }

  /// Re-renders an *editable* money [text] with [currencyCode]'s own decimals,
  /// rounding it via [roundToCurrencyPrecision] first.
  ///
  /// Returns [text] untouched when it does not parse (empty field, a lone `-`,
  /// a half-typed figure): there is nothing to re-render and rewriting it
  /// would fight the user mid-keystroke.
  ///
  /// Grouped like the fields keep it while typing (`4.500.000`), so the result
  /// can be handed straight back to a `TextEditingController` next to a
  /// `MoneyInputFormatter`.
  String reformatForCurrency(String text, String currencyCode) {
    final minor = parseMinor(text);
    if (minor == null) {
      return text;
    }
    return formatAmount(
      roundToCurrencyPrecision(minor, currencyCode),
      decimalDigits: currencyDecimals(currencyCode),
    );
  }

  /// Converts a major value (e.g. `12.34`) to minor units (`1234`).
  ///
  /// Only for values that are already numbers. To read **user input** use
  /// [parseMinor]: it never goes through `double`, so it cannot introduce a
  /// rounding error.
  static int toMinor(num major) => (major * _minorPerMajor).round();

  /// Converts minor units to a major value (`1234` → `12.34`). Use only for
  /// display/formatting, never to store or do arithmetic on amounts.
  static double toMajor(int amountMinor) => amountMinor / _minorPerMajor;

  /// Parses typed money into cents: `'12,34'` → `1234`, `'0,01'` → `1`.
  /// Returns `null` when the text is not a valid amount.
  ///
  /// Pure integer arithmetic on the digits — the text never becomes a `double`,
  /// so `'0,01'` cannot land on 0.999… and lose a cent.
  static int? parseMinor(String input) => parseScaled(input);

  /// Parses a typed annual rate into whole basis points: `'24,5'` (%) → `2450`.
  /// Basis points are just percent scaled by 100, hence the same conversion.
  static int? parseRateBps(String input) => parseScaled(input);

  /// Parses [input] into an integer scaled by 10^[decimals], with no `double`
  /// involved. Digits beyond [decimals] are rounded half-up.
  ///
  /// Accepts Spanish notation (`'1.234,56'`) and a plain decimal point
  /// (`'24.5'`). When both separators appear, the last one is the decimal one
  /// and the other is grouping; with a single `'.'` followed by exactly three
  /// digits it is read as grouping (`'1.234'` → 1234), per es-CO convention.
  static int? parseScaled(String input, {int decimals = 2}) {
    final sanitized = input.replaceAll(_ignorablePattern, '');
    if (sanitized.isEmpty) {
      return null;
    }

    final negative = sanitized.startsWith('-');
    final unsigned = sanitized.replaceFirst(_signPattern, '');
    if (unsigned.isEmpty || !_numberPattern.hasMatch(unsigned)) {
      return null;
    }

    // A comma is only ever a decimal separator here (es-CO groups with '.'), so
    // repeating it is not a number: '12,34,56' must be rejected, never read as
    // 123456.
    if (!unsigned.contains('.') && ','.allMatches(unsigned).length > 1) {
      return null;
    }

    final decimalSeparator = _decimalSeparatorOf(unsigned);
    final digitsOnly = decimalSeparator == null
        ? unsigned.replaceAll(_separatorPattern, '')
        : null;

    final String integerDigits;
    final String fractionDigits;
    if (digitsOnly != null) {
      integerDigits = digitsOnly;
      fractionDigits = '';
    } else {
      final index = unsigned.lastIndexOf(decimalSeparator!);
      integerDigits =
          unsigned.substring(0, index).replaceAll(_separatorPattern, '');
      fractionDigits = unsigned.substring(index + 1);
    }

    if (fractionDigits.contains(_separatorPattern)) {
      return null;
    }

    final integerPart = integerDigits.isEmpty ? 0 : int.tryParse(integerDigits);
    if (integerPart == null) {
      return null;
    }

    final padded = fractionDigits.padRight(decimals + 1, '0');
    final kept = padded.substring(0, decimals);
    final fractionPart = kept.isEmpty ? 0 : int.tryParse(kept);
    if (fractionPart == null) {
      return null;
    }
    // Half-up on the first dropped digit: never silently shave a cent off.
    final roundUp = int.parse(padded[decimals]) >= 5 ? 1 : 0;

    final scale = _pow10(decimals);
    final value = integerPart * scale + fractionPart + roundUp;
    return negative ? -value : value;
  }

  /// Which of `.` / `,` acts as the decimal separator, or `null` when the text
  /// has no decimals.
  static String? _decimalSeparatorOf(String value) {
    final lastDot = value.lastIndexOf('.');
    final lastComma = value.lastIndexOf(',');
    if (lastDot < 0 && lastComma < 0) {
      return null;
    }
    if (lastDot >= 0 && lastComma >= 0) {
      return lastDot > lastComma ? '.' : ',';
    }

    final separator = lastDot >= 0 ? '.' : ',';
    final index = lastDot >= 0 ? lastDot : lastComma;
    if (separator.allMatches(value).length > 1) {
      return null; // '1.234.567': grouping only.
    }
    final trailingDigits = value.length - index - 1;
    // '1.234' is one thousand two hundred thirty four in es-CO; '1,234' is not.
    if (separator == '.' && trailingDigits == 3) {
      return null;
    }
    return separator;
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  static final RegExp _ignorablePattern = RegExp(r'[\s $]');
  static final RegExp _signPattern = RegExp(r'^[-+]');
  static final RegExp _separatorPattern = RegExp(r'[.,]');
  static final RegExp _numberPattern = RegExp(r'^\d[\d.,]*$|^[.,]\d+$');
}
