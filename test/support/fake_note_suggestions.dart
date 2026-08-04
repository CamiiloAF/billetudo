import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/notes/domain/repositories/note_suggestions_repository.dart';
import 'package:billetudo/core/notes/domain/usecases/get_note_suggestions.dart';

/// Always resolves to an empty suggestion list — good enough for tests that
/// only need `NoteAutocompleteField` to build without a real database.
class FakeEmptyNoteSuggestionsRepository implements NoteSuggestionsRepository {
  const FakeEmptyNoteSuggestionsRepository();

  @override
  Future<List<String>> suggest(String query) async => const [];
}

/// Registers a `GetNoteSuggestions` in `getIt` that always returns no
/// suggestions, so any widget/golden test that renders a form containing the
/// shared `NoteAutocompleteField` (Transacciones, Deudas, Metas, Pagos
/// Programados) does not need a real database just to satisfy its default
/// `getIt<GetNoteSuggestions>()` lookup.
///
/// Call from `setUp` alongside `tearDown(getIt.reset)` — same convention as
/// every other fake this suite registers into `getIt`.
void registerFakeNoteSuggestions() {
  getIt.registerFactory<GetNoteSuggestions>(
    () => const GetNoteSuggestions(FakeEmptyNoteSuggestionsRepository()),
  );
}
