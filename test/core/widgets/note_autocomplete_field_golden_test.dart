import 'package:billetudo/core/notes/domain/repositories/note_suggestions_repository.dart';
import 'package:billetudo/core/notes/domain/usecases/get_note_suggestions.dart';
import 'package:billetudo/core/widgets/note_autocomplete_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden_helpers.dart';

/// Returns a fixed [suggestions] list regardless of the query, so tests
/// control the overlay's content deterministically instead of depending on
/// the real UNION query.
class _FakeNoteSuggestionsRepository implements NoteSuggestionsRepository {
  _FakeNoteSuggestionsRepository(this.suggestions);

  final List<String> suggestions;
  int calls = 0;

  @override
  Future<List<String>> suggest(String query) async {
    calls++;
    return suggestions;
  }
}

const List<String> _fourSuggestions = [
  'Uber al trabajo',
  'Uber al aeropuerto',
  'Viaje en Uber',
  'Uber compartido',
];

const List<String> _fiveSuggestions = [
  ..._fourSuggestions,
  'Almuerzo Uber Eats',
];

Widget _field({
  required List<String> suggestions,
  String initialValue = '',
  ValueChanged<String>? onChanged,
}) {
  return NoteAutocompleteField(
    key: const ValueKey('note-field'),
    label: 'Nota',
    initialValue: initialValue,
    hint: 'Agrega una nota',
    onChanged: onChanged ?? (_) {},
    getNoteSuggestions:
        GetNoteSuggestions(_FakeNoteSuggestionsRepository(suggestions)),
  );
}

void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  group('NoteAutocompleteField goldens', () {
    Future<void> golden(
      WidgetTester tester,
      String name, {
      required Brightness brightness,
      required List<String> suggestions,
      String query = 'Uber',
      String initialValue = '',
    }) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Padding(
            padding: const EdgeInsets.all(20),
            child: _field(
              suggestions: suggestions,
              initialValue: initialValue,
            ),
          ),
          brightness: brightness,
        ),
      );
      if (query.isNotEmpty) {
        await tester.enterText(find.byType(TextField), query);
      }
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/note_autocomplete_field_$name.png'),
      );
    }

    for (final brightness in Brightness.values) {
      final suffix = brightness == Brightness.light ? 'light' : 'dark';

      testWidgets('default, few suggestions ($suffix)', (tester) async {
        await golden(
          tester,
          'default_$suffix',
          brightness: brightness,
          suggestions: _fourSuggestions,
        );
      });

      testWidgets('5+ suggestions, capped with scroll ($suffix)',
          (tester) async {
        await golden(
          tester,
          'scroll_$suffix',
          brightness: brightness,
          suggestions: _fiveSuggestions,
        );
      });

      testWidgets('no matches, plain free text ($suffix)', (tester) async {
        await golden(
          tester,
          'no_matches_$suffix',
          brightness: brightness,
          suggestions: const [],
          query: 'Gasolina carro',
        );
      });
    }
  });
}
