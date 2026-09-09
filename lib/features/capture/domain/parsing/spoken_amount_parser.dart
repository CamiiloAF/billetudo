import 'capture_lexicon.dart';
import 'spoken_tokens.dart';

/// An amount found in the transcription, in minor units, plus the token span
/// it occupied so the note extractor can skip it.
class SpokenAmountMatch {
  const SpokenAmountMatch({
    required this.amountMinor,
    required this.isUncertain,
    required this.start,
    required this.end,
  });

  /// Always positive, always an integer of cents. No step of this parser ever
  /// holds a `double`: fractions are accumulated directly in minor units.
  final int amountMinor;

  /// True when the magnitude-elision heuristic had to guess the scale.
  final bool isUncertain;

  final int start;
  final int end;
}

/// Turns spoken money into `amountMinor`.
///
/// Handles digits ("20000", "20.000", "35.500"), Spanish/English number words
/// ("veinte mil", "ciento cincuenta mil", "two million"), es-CO colloquialisms
/// ("20 lucas", "un palo", "veinte barras") and cents ("doce con cincuenta").
///
/// ## Magnitude-elision heuristic (HU-04a, "gasté veinte")
///
/// Spoken Colombian Spanish drops the scale constantly: "gasté veinte" means
/// 20.000, not 20 — nothing costs twenty pesos. The rule applied here is
/// deliberately narrow and, above all, **declared**:
///
/// 1. it only fires for currencies whose everyday amounts are thousands
///    ([_thousandsElisionCurrencies]);
/// 2. it only fires when the speaker gave **no** explicit scale or unit — no
///    "mil", no "millones", no "lucas", no "pesos", no grouped digits;
/// 3. it only fires below [_elisionThreshold] major units;
/// 4. and when it fires, the result is flagged
///    [SpokenAmountMatch.isUncertain] so the flow asks the user to confirm the
///    amount instead of quietly registering a guess.
///
/// Point 4 is the whole point: the app may be helpful, but it must never be
/// confidently wrong about the single most important field.
class SpokenAmountParser {
  const SpokenAmountParser();

  /// Currencies where an unqualified small number is read as thousands.
  /// A currency outside this set keeps the literal value.
  static const Set<String> _thousandsElisionCurrencies = <String>{
    'COP',
    'CLP',
    'PYG',
  };

  static const int _elisionThreshold = 1000;
  static const int _elisionMultiplier = 1000;

  /// One hundred cents per major unit — the app stores every currency with two
  /// decimals (see `MoneyFormatter`), so this constant is not per-currency.
  static const int _minorPerMajor = 100;

  /// Words that are grammatically "one" but almost always an article in
  /// speech ("me tomé **un** tinto"). They only count as an amount when a
  /// scale word follows ("**un** palo").
  static const Set<String> _articleNumbers = <String>{
    'un',
    'uno',
    'una',
    'one',
  };

  SpokenAmountMatch? parse(
    SpokenTokens tokens, {
    required CaptureLexicon lexicon,
    required String currency,
  }) {
    for (var start = 0; start < tokens.length; start++) {
      if (!tokens.isFree(start) || !_canStartRun(tokens.normalized[start], lexicon)) {
        continue;
      }
      final match = _parseRun(tokens, start, lexicon, currency);
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  bool _canStartRun(String word, CaptureLexicon lexicon) =>
      lexicon.numberWords.containsKey(word) ||
      lexicon.scaleWords.containsKey(word) ||
      _digitsToMinor(word) != null;

  SpokenAmountMatch? _parseRun(
    SpokenTokens tokens,
    int start,
    CaptureLexicon lexicon,
    String currency,
  ) {
    var total = 0;
    var current = 0;
    var end = start;
    var sawValue = false;
    var sawScale = false;
    var explicitUnit = false;
    var explicitDecimals = false;
    var onlyArticle = false;

    var index = start;
    while (index < tokens.length && tokens.isFree(index)) {
      final word = tokens.normalized[index];

      final wordValue = lexicon.numberWords[word];
      if (wordValue != null) {
        if (sawValue && _articleNumbers.contains(word)) {
          break;
        }
        onlyArticle = !sawValue && _articleNumbers.contains(word);
        current += wordValue * _minorPerMajor;
        sawValue = true;
        end = ++index;
        continue;
      }

      if (lexicon.hundredMultiplier.contains(word)) {
        current = (current == 0 ? _minorPerMajor : current) * 100;
        sawValue = true;
        sawScale = true;
        onlyArticle = false;
        end = ++index;
        continue;
      }

      final scale = lexicon.scaleWords[word];
      if (scale != null) {
        current = (current == 0 ? _minorPerMajor : current) * scale;
        total += current;
        current = 0;
        sawValue = true;
        sawScale = true;
        onlyArticle = false;
        end = ++index;
        continue;
      }

      if (lexicon.andWords.contains(word)) {
        final next = index + 1 < tokens.length ? tokens.normalized[index + 1] : '';
        final continuesNumber = lexicon.numberWords.containsKey(next) ||
            lexicon.halfWords.contains(next);
        if (!sawValue || !continuesNumber || !tokens.isFree(index + 1)) {
          break;
        }
        index++;
        continue;
      }

      if (lexicon.halfWords.contains(word)) {
        if (!sawValue) {
          break;
        }
        // "tres y medio": half a major unit, expressed straight in cents.
        current += _minorPerMajor ~/ 2;
        onlyArticle = false;
        end = ++index;
        continue;
      }

      if (lexicon.decimalJoinWords.contains(word)) {
        final cents = _centsAfterJoin(tokens, index + 1, lexicon);
        if (cents == null) {
          break;
        }
        current += cents;
        explicitDecimals = true;
        onlyArticle = false;
        index += 2;
        end = index;
        continue;
      }

      if (lexicon.currencyWords.contains(word)) {
        if (!sawValue) {
          break;
        }
        explicitUnit = true;
        end = ++index;
        break;
      }

      final digits = _digitsToMinor(word);
      if (digits != null) {
        if (sawValue) {
          break;
        }
        current += digits.minor;
        explicitDecimals = explicitDecimals || digits.isDecimal;
        explicitUnit = explicitUnit || digits.isGrouped;
        sawValue = true;
        onlyArticle = false;
        end = ++index;
        continue;
      }

      break;
    }

    total += current;
    if (!sawValue || total <= 0 || (onlyArticle && !sawScale)) {
      return null;
    }

    explicitUnit = explicitUnit || sawScale;
    final major = total ~/ _minorPerMajor;
    final elides = !explicitUnit &&
        !explicitDecimals &&
        major < _elisionThreshold &&
        _thousandsElisionCurrencies.contains(currency.toUpperCase());

    return SpokenAmountMatch(
      amountMinor: elides ? total * _elisionMultiplier : total,
      isUncertain: elides,
      start: start,
      end: end,
    );
  }

  /// Cents introduced by "con"/"point": one following number below 100.
  int? _centsAfterJoin(SpokenTokens tokens, int index, CaptureLexicon lexicon) {
    if (index >= tokens.length || !tokens.isFree(index)) {
      return null;
    }
    final word = tokens.normalized[index];
    final wordValue = lexicon.numberWords[word];
    if (wordValue != null && wordValue < 100) {
      return wordValue;
    }
    final digits = _digitsToMinor(word);
    if (digits != null && !digits.isDecimal && !digits.isGrouped) {
      final value = digits.minor ~/ _minorPerMajor;
      if (value < 100) {
        return value;
      }
    }
    return null;
  }

  static final RegExp _grouped = RegExp(r'^\d{1,3}(?:[.,]\d{3})+$');
  static final RegExp _decimal = RegExp(r'^\d+[.,]\d{1,2}$');
  static final RegExp _plain = RegExp(r'^\d+$');

  /// Parses a digit token into cents.
  ///
  /// `20.000` is grouped thousands (3 digits after the separator), `12,50` is
  /// cents (1-2 digits). That asymmetry is exactly how es-CO writes money and
  /// it is why the check on group length comes first.
  static _DigitAmount? _digitsToMinor(String token) {
    if (_grouped.hasMatch(token)) {
      final value = int.tryParse(token.replaceAll(RegExp(r'[.,]'), ''));
      return value == null
          ? null
          : _DigitAmount(value * _minorPerMajor, isGrouped: true);
    }
    if (_decimal.hasMatch(token)) {
      final parts = token.split(RegExp(r'[.,]'));
      final whole = int.tryParse(parts.first);
      final fraction = int.tryParse(parts.last.padRight(2, '0'));
      return whole == null || fraction == null
          ? null
          : _DigitAmount(whole * _minorPerMajor + fraction, isDecimal: true);
    }
    if (_plain.hasMatch(token)) {
      final value = int.tryParse(token);
      return value == null ? null : _DigitAmount(value * _minorPerMajor);
    }
    return null;
  }
}

class _DigitAmount {
  const _DigitAmount(this.minor, {this.isDecimal = false, this.isGrouped = false});

  final int minor;
  final bool isDecimal;
  final bool isGrouped;
}
