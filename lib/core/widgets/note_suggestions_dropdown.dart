import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'note_suggestion_row.dart';

/// The `Suggestions Dropdown` floated below `NoteAutocompleteField`'s Input
/// Box: grows freely up to 4 full rows, then caps at `maxHeight: 200` with
/// internal scroll from the 5th suggestion on, so it never covers the rest
/// of the form on mobile.
class NoteSuggestionsDropdown extends StatelessWidget {
  const NoteSuggestionsDropdown({
    required this.suggestions,
    required this.onSelected,
    super.key,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  static const double maxHeight = 200;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scrolls = suggestions.length > 4;

    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('note-suggestions-dropdown'),
        constraints: scrolls
            ? const BoxConstraints(maxHeight: maxHeight)
            : const BoxConstraints(),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: scrolls
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: suggestions.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, thickness: 1, color: colors.border),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return NoteSuggestionRow(
              label: suggestion,
              onTap: () => onSelected(suggestion),
            );
          },
        ),
      ),
    );
  }
}
