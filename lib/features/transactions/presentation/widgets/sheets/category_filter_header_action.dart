import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// A 44px-tall tap area for the header's "Todas"/"Ninguna" actions.
class CategoryFilterHeaderAction extends StatelessWidget {
  const CategoryFilterHeaderAction({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: colors.primary),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
