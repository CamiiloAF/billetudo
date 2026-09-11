/// Turns the amount fragment a rule captured into an integer of minor units
/// (cents), the only money representation this project allows.
///
/// It must survive the three real formats already seen in the wild, which is
/// why the separator is decided by inspection instead of by a fixed locale:
///
/// * `$58.470,00` (Nu)          -> `5847000`
/// * `$1`         (Nequi)       -> `100`
/// * `38.000,00`  (Wallet, COP after the figure) -> `3800000`
/// * `128.920,00` (Nu, no `$`)  -> `12892000`
///
/// The 1000x mistake this guards against: in es-CO `128.920,00` is one hundred
/// twenty-eight thousand pesos, not one hundred twenty-eight.
///
/// **Kept byte-for-byte in sync with `NotificationAmountParser.kt`.** Any
/// change here must be mirrored there and covered by the same test cases.
abstract final class NotificationAmountParser {
  /// Largest amount a capture may carry: `Int32`, the ceiling of the Kotlin
  /// engine. About 21 million pesos; anything above it is a parsing accident,
  /// not a purchase.
  static const int _maxAmountMinor = 2147483647;

  /// Returns the positive amount in cents, or `null` when [raw] holds no
  /// usable figure. `null` means NO CAPTURE (HU-03: a capture without an
  /// amount saves no work, it only adds noise to the inbox).
  static int? parseMinor(String raw) {
    // Drop currency symbols, spaces, non-breaking spaces and letters (`COP`).
    var cleaned = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
    // A trailing separator is punctuation of the sentence, not of the number
    // (`por $1.` -> `1`).
    cleaned = cleaned.replaceAll(RegExp(r'[.,]+$'), '');
    if (cleaned.isEmpty) {
      return null;
    }

    final int lastDot = cleaned.lastIndexOf('.');
    final int lastComma = cleaned.lastIndexOf(',');
    final int lastSeparator = lastDot > lastComma ? lastDot : lastComma;

    String digits = cleaned;
    String fraction = '';
    if (lastSeparator >= 0) {
      final String separator = cleaned[lastSeparator];
      final String tail = cleaned.substring(lastSeparator + 1);
      final bool bothPresent = lastDot >= 0 && lastComma >= 0;
      final int occurrences = separator.allMatches(cleaned).length;
      // Decimal when the two separator kinds coexist (the last one wins), or
      // when a single separator is followed by something other than a group of
      // exactly three digits. `45.900` is forty-five thousand nine hundred,
      // `45.90` is forty-five pesos ninety cents.
      final bool isDecimal =
          bothPresent || (occurrences == 1 && tail.length != 3);
      if (isDecimal) {
        digits = cleaned.substring(0, lastSeparator);
        fraction = tail;
      }
    }

    final String integerDigits = digits.replaceAll(RegExp(r'[.,]'), '');
    if (integerDigits.isEmpty) {
      return null;
    }
    final int? units = int.tryParse(integerDigits);
    if (units == null) {
      return null;
    }

    final int cents = _centsFromFraction(fraction);
    final int amountMinor = units * 100 + cents;
    // Always POSITIVE: the sign is carried by the entry type, never by the
    // amount. A zero is not a movement. The upper bound keeps parity with the
    // Kotlin engine, where the value has to fit in an `Int`.
    if (amountMinor <= 0 || amountMinor > _maxAmountMinor) {
      return null;
    }
    return amountMinor;
  }

  static int _centsFromFraction(String fraction) {
    if (fraction.isEmpty) {
      return 0;
    }
    final String onlyDigits = fraction.replaceAll(RegExp(r'[^0-9]'), '');
    if (onlyDigits.isEmpty) {
      return 0;
    }
    if (onlyDigits.length == 1) {
      return int.parse(onlyDigits) * 10;
    }
    final int firstTwo = int.parse(onlyDigits.substring(0, 2));
    if (onlyDigits.length == 2) {
      return firstTwo;
    }
    // More than two decimals: round half up on the third digit.
    final int third = int.parse(onlyDigits.substring(2, 3));
    return third >= 5 ? firstTwo + 1 : firstTwo;
  }
}
