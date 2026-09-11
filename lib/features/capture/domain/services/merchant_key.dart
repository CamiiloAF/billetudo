import '../../../../core/utils/text_normalizer.dart';

final RegExp _whitespace = RegExp(r'\s+');

/// Normalizes a merchant fragment into the key `MerchantCategoryLearning`
/// stores (HU-06): UPPERCASE, diacritics stripped, whitespace collapsed and
/// trimmed.
///
/// Why normalize at all: banks write the same merchant differently across
/// notifications (`Éxito Calle 80`, `EXITO  CALLE 80`), and an un-normalized
/// key would learn the same merchant several times and suggest nothing.
/// Upper case (not the lower case of [normalizeForSearch]) because the stored
/// key is also what a future debugging/settings screen shows, and merchant
/// names arrive upper-cased from the issuers.
///
/// Returns `null` for a merchant that normalizes to nothing — there is no key
/// to learn against, and an empty key would collapse every unnamed merchant
/// into one bogus association.
String? merchantKeyFor(String? merchantRaw) {
  if (merchantRaw == null) {
    return null;
  }
  final normalized = normalizeForSearch(merchantRaw)
      .replaceAll(_whitespace, ' ')
      .trim()
      .toUpperCase();
  return normalized.isEmpty ? null : normalized;
}
