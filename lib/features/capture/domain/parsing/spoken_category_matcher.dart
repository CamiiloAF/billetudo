import '../../../../core/utils/text_normalizer.dart';
import '../../../categories/domain/entities/category.dart';
import 'capture_lexicon.dart';
import 'spoken_tokens.dart';

/// A category resolved from the transcription plus the span it occupied.
class SpokenCategoryMatch {
  const SpokenCategoryMatch({
    required this.category,
    required this.start,
    required this.end,
  });

  final Category category;
  final int start;
  final int end;
}

/// Resolves the category from what was said (HU-04b).
///
/// Two passes, in this order and never the other way round:
///
/// 1. **The user's own category names** — including subcategories. If someone
///    renamed "Alimentación" to "Comida", "comida" must land there. It is
///    their vocabulary, not ours.
/// 2. **The built-in synonym dictionary** (es/en, local, versioned with the
///    app), which only ever *suggests* a name that still has to exist among
///    the user's categories.
///
/// The most specific match wins: "gasolina" lands on the subcategory, not on
/// its Transporte root. A tie, or no match at all, leaves the category empty
/// and lets the form ask for it — picking "the most used one" would be a
/// silent wrong answer on a required field.
class SpokenCategoryMatcher {
  const SpokenCategoryMatcher();

  SpokenCategoryMatch? match(
    SpokenTokens tokens, {
    required List<Category> categories,
    required CaptureLexicon lexicon,
    required CategoryKind kind,
  }) {
    final candidates =
        categories.where((category) => category.kind == kind).toList();
    if (candidates.isEmpty) {
      return null;
    }
    return _matchByName(tokens, candidates) ??
        _matchBySynonym(tokens, candidates, lexicon);
  }

  SpokenCategoryMatch? _matchByName(
    SpokenTokens tokens,
    List<Category> candidates,
  ) {
    SpokenCategoryMatch? best;
    var bestIsAmbiguous = false;
    for (final category in candidates) {
      final words = _words(category.name);
      if (words.isEmpty) {
        continue;
      }
      final index = tokens.indexOfSequence(words);
      if (index < 0) {
        continue;
      }
      final candidate = SpokenCategoryMatch(
        category: category,
        start: index,
        end: index + words.length,
      );
      if (best == null) {
        best = candidate;
        continue;
      }
      final comparison = _compare(candidate, best);
      if (comparison > 0) {
        best = candidate;
        bestIsAmbiguous = false;
      } else if (comparison == 0) {
        bestIsAmbiguous = true;
      }
    }
    return bestIsAmbiguous ? null : best;
  }

  /// Positive when [a] is the better match: more words matched first, then a
  /// subcategory over a root.
  int _compare(SpokenCategoryMatch a, SpokenCategoryMatch b) {
    final byLength = (a.end - a.start).compareTo(b.end - b.start);
    if (byLength != 0) {
      return byLength;
    }
    final aIsSub = a.category.parentId != null;
    final bIsSub = b.category.parentId != null;
    if (aIsSub == bIsSub) {
      return 0;
    }
    return aIsSub ? 1 : -1;
  }

  SpokenCategoryMatch? _matchBySynonym(
    SpokenTokens tokens,
    List<Category> candidates,
    CaptureLexicon lexicon,
  ) {
    for (final index in tokens.freeIndices) {
      final targets = lexicon.categorySynonyms[tokens.normalized[index]];
      if (targets == null) {
        continue;
      }
      for (final target in targets) {
        final matching = candidates
            .where((category) => normalizeForSearch(category.name) == target)
            .toList();
        if (matching.length == 1) {
          return SpokenCategoryMatch(
            category: matching.first,
            start: index,
            end: index + 1,
          );
        }
        if (matching.length > 1) {
          // Same name twice under different roots: ambiguous on purpose.
          return null;
        }
      }
    }
    return null;
  }

  List<String> _words(String name) => normalizeForSearch(name)
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
}
