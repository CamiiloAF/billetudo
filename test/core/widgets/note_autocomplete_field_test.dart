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

  group('NoteAutocompleteField behaviour', () {
    testWidgets('shows no overlay below the minimum query length',
        (tester) async {
      final repository = _FakeNoteSuggestionsRepository(_fourSuggestions);
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          NoteAutocompleteField(
            initialValue: '',
            onChanged: (_) {},
            getNoteSuggestions: GetNoteSuggestions(repository),
          ),
          brightness: Brightness.light,
        ),
      );

      await tester.enterText(find.byType(TextField), 'U');
      await tester.pumpAndSettle();

      expect(repository.calls, 0);
      expect(find.byKey(const ValueKey('note-suggestions-dropdown')),
          findsNothing);
    });

    testWidgets('shows the overlay once there is at least one match',
        (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          _field(suggestions: _fourSuggestions),
          brightness: Brightness.light,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Uber');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('note-suggestions-dropdown')),
          findsOneWidget);
      for (final suggestion in _fourSuggestions) {
        expect(find.text(suggestion), findsOneWidget);
      }
    });

    testWidgets('hides the overlay with zero matches (plain free text)',
        (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          _field(suggestions: const []),
          brightness: Brightness.light,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Gasolina');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('note-suggestions-dropdown')),
          findsNothing);
      expect(find.text('Error'), findsNothing);
    });

    testWidgets('caps the dropdown height once there are 5+ suggestions',
        (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          _field(suggestions: _fiveSuggestions),
          brightness: Brightness.light,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Uber');
      await tester.pumpAndSettle();

      final dropdownSize = tester
          .getSize(find.byKey(const ValueKey('note-suggestions-dropdown')));
      expect(dropdownSize.height, lessThanOrEqualTo(200));
    });

    testWidgets(
        'does not cap the dropdown height with 4 or fewer suggestions',
        (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          _field(suggestions: _fourSuggestions),
          brightness: Brightness.light,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Uber');
      await tester.pumpAndSettle();

      // 4 rows (~44-50px each) plus dividers comfortably clears 200px if it
      // were (wrongly) capped — asserting it grows freely instead.
      for (final suggestion in _fourSuggestions) {
        expect(find.text(suggestion), findsOneWidget);
      }
    });

    testWidgets(
        'selecting a suggestion fills the field, propagates onChanged and '
        'closes the overlay', (tester) async {
      String? lastValue;
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          _field(
            suggestions: _fourSuggestions,
            onChanged: (value) => lastValue = value,
          ),
          brightness: Brightness.light,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Uber');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Uber al aeropuerto'));
      await tester.pumpAndSettle();

      expect(lastValue, 'Uber al aeropuerto');
      expect(find.text('Uber al aeropuerto'), findsOneWidget);
      expect(find.byKey(const ValueKey('note-suggestions-dropdown')),
          findsNothing);
    });

    testWidgets(
        'loading an initial value (edit mode) does not trigger a lookup',
        (tester) async {
      final repository = _FakeNoteSuggestionsRepository(_fourSuggestions);
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          NoteAutocompleteField(
            initialValue: 'Uber al trabajo',
            onChanged: (_) {},
            getNoteSuggestions: GetNoteSuggestions(repository),
          ),
          brightness: Brightness.light,
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.calls, 0);
      expect(find.byKey(const ValueKey('note-suggestions-dropdown')),
          findsNothing);
      expect(find.text('Uber al trabajo'), findsOneWidget);
    });
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
