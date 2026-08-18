import '../../domain/entities/csv_dialect.dart';

/// Result of [DecimalAmountParser.parse].
class ParsedDecimalAmount {
  const ParsedDecimalAmount({required this.minorUnits, required this.rounded});

  /// Always the *magnitude* the caller asked for — this parser does not
  /// decide sign-as-direction; a leading `-` in the source is honored as a
  /// negative value (used by the "no type column" convention upstream).
  final int minorUnits;

  /// True when the source had more decimal digits than `currencyDecimals`
  /// admits and at least one of the dropped digits was non-zero — the value
  /// was rounded half-up, never truncated silently and never discarded
  /// (`docs/requirements/fase-1/11-import-export.md` §Montos).
  final bool rounded;
}

/// Converts a decimal amount string from a CSV cell into exact minor units
/// (cents), per project rule: **never `double`**. `19.99 * 100` in floating
/// point yields `1998.9999...`; this does the same conversion with pure
/// integer arithmetic on the digit strings instead.
///
/// Lives in `data/` (never `domain/`) per
/// `docs/requirements/fase-1/11-import-export.md`: "la conversión decimal → centavos
/// ocurre en el borde (parser/serializador), nunca dentro del dominio".
/// [DecimalConvention] is already resolved by the time this runs — the
/// mapping step, not this parser, decides which separator means what for a
/// given file.
abstract final class DecimalAmountParser {
  /// Parses [raw] using [convention] and rounds half-up to [currencyDecimals].
  /// Returns `null` when [raw] is not a valid number under [convention]
  /// (empty, malformed, more than one decimal separator).
  static ParsedDecimalAmount? parse(
    String raw, {
    required DecimalConvention convention,
    required int currencyDecimals,
  }) {
    var body = raw.trim();
    if (body.isEmpty) {
      return null;
    }

    var negative = false;
    if (body.startsWith('-')) {
      negative = true;
      body = body.substring(1);
    } else if (body.startsWith('+')) {
      body = body.substring(1);
    }
    body = body.replaceAll(RegExp(r'\s'), '');
    if (body.isEmpty) {
      return null;
    }

    final decimalChar = convention == DecimalConvention.dot ? '.' : ',';
    final groupingChar = convention == DecimalConvention.dot ? ',' : '.';

    final withoutGrouping = body.replaceAll(groupingChar, '');
    final parts = withoutGrouping.split(decimalChar);
    if (parts.length > 2) {
      return null;
    }

    final integerPart = parts[0];
    final fractionPart = parts.length == 2 ? parts[1] : '';
    if (integerPart.isEmpty && fractionPart.isEmpty) {
      return null;
    }
    if (!_digitsOnly.hasMatch(integerPart) || !_digitsOnly.hasMatch(fractionPart)) {
      return null;
    }

    final integerValue = integerPart.isEmpty ? 0 : int.parse(integerPart);

    var rounded = false;
    int fractionValue;
    if (fractionPart.length <= currencyDecimals) {
      final padded = fractionPart.padRight(currencyDecimals, '0');
      fractionValue = padded.isEmpty ? 0 : int.parse(padded);
    } else {
      final kept = fractionPart.substring(0, currencyDecimals);
      final extra = fractionPart.substring(currencyDecimals);
      fractionValue = kept.isEmpty ? 0 : int.parse(kept);
      rounded = extra.replaceAll('0', '').isNotEmpty;
      // Half-up on the first dropped digit — same rule
      // `MoneyFormatter.parseScaled` uses for typed input.
      if (int.parse(extra[0]) >= 5) {
        fractionValue += 1;
      }
    }

    var scale = 1;
    for (var i = 0; i < currencyDecimals; i++) {
      scale *= 10;
    }
    final minorUnits = integerValue * scale + fractionValue;

    return ParsedDecimalAmount(
      minorUnits: negative ? -minorUnits : minorUnits,
      rounded: rounded,
    );
  }

  static final RegExp _digitsOnly = RegExp(r'^\d*$');

  /// The inverse direction, for export (HU-01 §Montos): `1234` cents at 2
  /// decimals -> `"12.34"`. Always a dot decimal, no thousands separator,
  /// [minorUnits] assumed non-negative (`Transactions.amountMinor` always
  /// is — direction is a separate column). Pure integer/string arithmetic,
  /// same rule as [parse].
  static String format(int minorUnits, {required int currencyDecimals}) {
    if (currencyDecimals == 0) {
      return minorUnits.toString();
    }
    var scale = 1;
    for (var i = 0; i < currencyDecimals; i++) {
      scale *= 10;
    }
    final wholePart = minorUnits ~/ scale;
    final fractionPart = (minorUnits % scale).toString().padLeft(currencyDecimals, '0');
    return '$wholePart.$fractionPart';
  }
}
