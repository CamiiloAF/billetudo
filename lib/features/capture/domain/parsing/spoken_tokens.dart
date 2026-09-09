import '../../../../core/utils/text_normalizer.dart';

/// The transcription split into words, with a "consumed" mark per word.
///
/// Every extractor (amount, date, account, category, polarity) claims the
/// words it used, so the note extractor can simply take what nobody claimed
/// (HU-04e) without re-running any of them. Matching always happens on the
/// [normalized] form (lowercase, no diacritics, no trailing punctuation) while
/// [raw] keeps the original word for the note.
class SpokenTokens {
  factory SpokenTokens(String transcript) {
    final raw = _split(transcript);
    return SpokenTokens._(
      raw,
      raw.map(_normalizeToken).toList(growable: false),
    );
  }

  SpokenTokens._(this.raw, this.normalized)
      : _consumed = List<bool>.filled(raw.length, false);

  static List<String> _split(String transcript) => transcript
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .toList(growable: false);

  /// Lowercases, strips diacritics and drops punctuation that a recognizer
  /// glues to a word (`"almuerzo,"` -> `almuerzo`). Digit group separators are
  /// kept: `20.000` must survive as one token.
  static String _normalizeToken(String word) {
    final normalized = normalizeForSearch(word);
    return normalized.replaceAll(RegExp(r'''^[¿¡"'(\[]+|[,.;:!?"')\]]+$'''), '')
        // A number like `20.000,` loses its trailing comma above; anything
        // still left that is not a letter, digit or inner separator is noise.
        .replaceAll(RegExp(r'[¿¡!?;:]'), '');
  }

  final List<String> raw;
  final List<String> normalized;
  final List<bool> _consumed;

  int get length => raw.length;

  bool isFree(int index) =>
      index >= 0 && index < raw.length && !_consumed[index];

  /// Marks `[start, end)` as used by an extractor.
  void consume(int start, int end) {
    for (var i = start; i < end && i < _consumed.length; i++) {
      _consumed[i] = true;
    }
  }

  /// Indices still unclaimed, in order.
  List<int> get freeIndices => <int>[
        for (var i = 0; i < raw.length; i++)
          if (!_consumed[i]) i,
      ];

  /// Whether the normalized words at `[start, start + words.length)` are all
  /// free and equal to [words].
  bool matchesAt(int start, List<String> words) {
    if (start < 0 || start + words.length > raw.length) {
      return false;
    }
    for (var i = 0; i < words.length; i++) {
      if (!isFree(start + i) || normalized[start + i] != words[i]) {
        return false;
      }
    }
    return true;
  }

  /// Index of the first free occurrence of the [words] sequence, or `-1`.
  int indexOfSequence(List<String> words) {
    if (words.isEmpty) {
      return -1;
    }
    for (var start = 0; start + words.length <= raw.length; start++) {
      if (matchesAt(start, words)) {
        return start;
      }
    }
    return -1;
  }

  /// The raw words still unclaimed, trimmed of the punctuation the note
  /// should not carry over.
  List<String> get freeWords => <String>[
        for (final index in freeIndices)
          raw[index].replaceAll(RegExp(r'''^[¿¡"'(\[]+|[,.;:!?"')\]]+$'''), ''),
      ];
}
