/// Maps accented/diacritic characters to their plain ASCII counterpart, so
/// search comparisons can be accent-insensitive (e.g. "prestamos" should
/// match "Préstamos"). Dart has no built-in diacritics stripper, so this is a
/// small manual table covering the characters used in Spanish text.
const Map<String, String> _diacriticsMap = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'Á': 'A',
  'À': 'A',
  'Ä': 'A',
  'Â': 'A',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'É': 'E',
  'È': 'E',
  'Ë': 'E',
  'Ê': 'E',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'Í': 'I',
  'Ì': 'I',
  'Ï': 'I',
  'Î': 'I',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'Ó': 'O',
  'Ò': 'O',
  'Ö': 'O',
  'Ô': 'O',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'Ú': 'U',
  'Ù': 'U',
  'Ü': 'U',
  'Û': 'U',
  'ñ': 'n',
  'Ñ': 'N',
};

/// Strips diacritics from [input] and lowercases it, so it can be compared
/// against another normalized string regardless of accents or case. Used to
/// make search/filter fields (e.g. the category picker) accent-insensitive.
String normalizeForSearch(String input) {
  final buffer = StringBuffer();
  for (final char in input.split('')) {
    buffer.write(_diacriticsMap[char] ?? char);
  }
  return buffer.toString().toLowerCase();
}
