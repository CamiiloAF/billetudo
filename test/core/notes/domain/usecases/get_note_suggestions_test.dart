import 'package:billetudo/core/notes/domain/repositories/note_suggestions_repository.dart';
import 'package:billetudo/core/notes/domain/usecases/get_note_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNoteSuggestionsRepository implements NoteSuggestionsRepository {
  _FakeNoteSuggestionsRepository(this.result);

  final List<String> result;
  String? lastQuery;
  int calls = 0;

  @override
  Future<List<String>> suggest(String query) async {
    calls++;
    lastQuery = query;
    return result;
  }
}

void main() {
  group('GetNoteSuggestions', () {
    test('returns an empty list without querying below the minimum length',
        () async {
      final repository = _FakeNoteSuggestionsRepository(['almuerzo']);
      final useCase = GetNoteSuggestions(repository);

      final result = await useCase('a');

      expect(result, isEmpty);
      expect(repository.calls, 0);
    });

    test('returns an empty list without querying for a blank/whitespace query',
        () async {
      final repository = _FakeNoteSuggestionsRepository(['almuerzo']);
      final useCase = GetNoteSuggestions(repository);

      final result = await useCase('   ');

      expect(result, isEmpty);
      expect(repository.calls, 0);
    });

    test('trims the query before delegating to the repository', () async {
      final repository = _FakeNoteSuggestionsRepository(['almuerzo']);
      final useCase = GetNoteSuggestions(repository);

      await useCase('  almu  ');

      expect(repository.lastQuery, 'almu');
      expect(repository.calls, 1);
    });

    test('queries once the query reaches the minimum length', () async {
      final repository = _FakeNoteSuggestionsRepository(['almuerzo']);
      final useCase = GetNoteSuggestions(repository);

      final result = await useCase('al');

      expect(result, ['almuerzo']);
      expect(repository.calls, 1);
    });

    test('caps the result at maxSuggestions even if the repository over-returns',
        () async {
      final overLimit = List.generate(15, (i) => 'nota $i');
      final repository = _FakeNoteSuggestionsRepository(overLimit);
      final useCase = GetNoteSuggestions(repository);

      final result = await useCase('nota');

      expect(result, hasLength(GetNoteSuggestions.maxSuggestions));
      expect(result, overLimit.take(GetNoteSuggestions.maxSuggestions));
    });
  });
}
