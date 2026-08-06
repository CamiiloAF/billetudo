/// Cross-cutting port for the shared note-autocomplete feature (`taqc1`).
///
/// The user's free-text "nota" field is captured in four different places
/// (transactions, goal contributions, debt entries, scheduled payments) and
/// the autocomplete overlay suggests past values regardless of where they
/// were originally typed. Implementations live in `data/` and never leak
/// Drift types here.
abstract class NoteSuggestionsRepository {
  /// Returns up to 10 distinct notes (case-insensitively) whose text
  /// contains [query], most frequently used first and, on a tie, most
  /// recently used first.
  ///
  /// [query] is assumed to already be trimmed and past the caller's minimum
  /// length — this port does no validation of its own, that lives in
  /// `GetNoteSuggestions`.
  Future<List<String>> suggest(String query);
}
