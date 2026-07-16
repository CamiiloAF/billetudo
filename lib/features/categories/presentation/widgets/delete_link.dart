import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Delete Link` component: `trash-2` icon + label, `height: 44`.
///
/// `categorias.md` notes Cuentas already has an equivalent link built inline
/// in its detail page; this stays local to Categories rather than a forced
/// early promotion to `core/widgets` (the promotion rule for shared widgets
/// needs a second real usage first, and the two are not wired to a common
/// caller yet).
class DeleteLink extends StatelessWidget {
  const DeleteLink({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 44,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.trash, size: 20, color: colors.expense),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.expense,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
