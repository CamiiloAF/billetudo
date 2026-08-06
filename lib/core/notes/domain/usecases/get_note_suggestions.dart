import 'package:injectable/injectable.dart';

import '../repositories/note_suggestions_repository.dart';

/// Resolves note-autocomplete suggestions for the shared `NoteAutocompleteField`
/// (`taqc1`).
///
/// Owns the business rule the repository is deliberately unaware of: below
/// [minQueryLength] characters (after trimming) the field should behave as
/// plain free text, so this returns an empty list WITHOUT touching the
/// database — opening a note field must never list the entire note history.
@injectable
class GetNoteSuggestions {
  const GetNoteSuggestions(this._repository);

  final NoteSuggestionsRepository _repository;

  /// Minimum trimmed query length before a database query is even attempted.
  static const int minQueryLength = 2;

  /// Maximum number of suggestions returned, enforced again here (not just
  /// trusted from the repository) so the use case's contract stands on its
  /// own regardless of the implementation behind it.
  static const int maxSuggestions = 10;

  Future<List<String>> call(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength) {
      return const [];
    }

    final suggestions = await _repository.suggest(trimmed);
    return suggestions.take(maxSuggestions).toList();
  }
}
