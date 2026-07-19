import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';

/// HU-07: creates a tag on the fly, from either the transaction form or the
/// tag filter (`NazyV`, "Sheet - Nueva Etiqueta"). Purely a text prompt — the
/// actual creation (and reuse of an existing tag with the same name) lives in
/// `CreateTag`.
///
/// The "Field - Nombre" (`c0ONUy`) is the same look as `wOlOA`
/// (`TransactionFormFieldButton`, label above an input box with a leading
/// icon) but editable directly rather than opening a picker, so it can't
/// reuse that widget — it builds the same decoration by hand.
class NewTagSheet extends StatefulWidget {
  const NewTagSheet({super.key});

  static Future<String?> show(BuildContext context) =>
      BottomSheetBase.show<String>(
        context,
        builder: (context) => const NewTagSheet(),
      );

  @override
  State<NewTagSheet> createState() => _NewTagSheetState();
}

class _NewTagSheetState extends State<NewTagSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    return Padding(
      // Not redundant with BottomSheetBase's own padding: this keeps the
      // field clear of the keyboard, which its static bottom inset can't do.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.newTagSheetTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.newTagNameHint,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusField),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.tag, size: 18, color: colors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) => Navigator.of(context).pop(value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_controller.text),
              icon: const Icon(LucideIcons.check, size: 18),
              label: Text(l10n.commonCreate),
            ),
          ),
        ],
      ),
    );
  }
}
