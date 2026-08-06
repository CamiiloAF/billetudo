import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One editable "value that means X" text field of the column-mode form in
/// `ImportTypeValuesSheet`. Kept as its own widget (not an inline builder)
/// so each of the three fields is a single, independently testable and
/// reusable unit.
class ImportLiteralField extends StatelessWidget {
  const ImportLiteralField({
    required this.label,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
        ),
      ],
    );
  }
}
