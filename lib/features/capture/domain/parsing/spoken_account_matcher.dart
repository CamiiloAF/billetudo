import '../../../../core/utils/text_normalizer.dart';
import '../../../accounts/domain/entities/account.dart';
import 'spoken_tokens.dart';

/// An account named in the transcription plus the span it occupied.
class SpokenAccountMatch {
  const SpokenAccountMatch({
    required this.account,
    required this.start,
    required this.end,
  });

  final Account account;
  final int start;
  final int end;
}

/// Resolves "pagué con Nequi", "en efectivo", "con la tarjeta de Bancolombia"
/// against the user's own account names (HU-04c).
///
/// Matching is accent- and case-insensitive and accepts a partial name
/// ("banco" -> "Bancolombia") **only when it is unambiguous**: two accounts
/// starting the same way resolve to none, because silently picking one would
/// put the movement on the wrong balance. When nothing matches, the caller
/// keeps the form's usual default account rather than inventing a
/// voice-specific rule.
class SpokenAccountMatcher {
  const SpokenAccountMatcher();

  /// Shortest partial word accepted, so "de"/"la" never latch onto an account.
  static const int _minPartialLength = 4;

  SpokenAccountMatch? match(SpokenTokens tokens, List<Account> accounts) {
    final candidates = accounts.where((account) => !account.archived).toList();
    if (candidates.isEmpty) {
      return null;
    }

    // Full name first: the longest exact run wins, so "Banco de Bogotá" beats
    // an account merely called "Banco".
    SpokenAccountMatch? best;
    for (final account in candidates) {
      final words = _words(account.name);
      if (words.isEmpty) {
        continue;
      }
      final index = tokens.indexOfSequence(words);
      if (index < 0) {
        continue;
      }
      if (best == null || words.length > best.end - best.start) {
        best = SpokenAccountMatch(
          account: account,
          start: index,
          end: index + words.length,
        );
      }
    }
    if (best != null) {
      return best;
    }

    // Partial, and only when exactly one account can claim the word.
    for (final index in tokens.freeIndices) {
      final word = tokens.normalized[index];
      if (word.length < _minPartialLength) {
        continue;
      }
      final matching = candidates
          .where((account) => _words(account.name).any(
                (accountWord) => accountWord.startsWith(word),
              ))
          .toList();
      if (matching.length == 1) {
        return SpokenAccountMatch(
          account: matching.first,
          start: index,
          end: index + 1,
        );
      }
    }
    return null;
  }

  List<String> _words(String name) => normalizeForSearch(name)
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
}
