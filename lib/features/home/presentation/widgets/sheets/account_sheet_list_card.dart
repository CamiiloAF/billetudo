import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// `AccountSheet`'s `List Card` (`bRo5A`/`auMCE`/`zsAbo`,
/// `design-system/billetudo/pages/inicio.md` § "Hoja de cuenta"): `$surface`
/// fill, `$border` 1px stroke, `cornerRadius:16`, wrapping the sheet's
/// `SheetMenuRow`s with a 1px `$border` divider between each pair.
class AccountSheetListCard extends StatelessWidget {
  const AccountSheetListCard({required this.rows, super.key});

  /// One `SheetMenuRow` per entry — a single "Ajustes" row for the "sin
  /// cuenta" variant, "Estado de sincronización" + "Ajustes" otherwise.
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Container(height: 1, color: colors.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}
