import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../utils/category_appearance.dart';
import 'icon_tile.dart';

/// What the sheet resolves to when the user picks an icon/color.
typedef CategoryAppearancePick = ({String icon, String color});

/// The icon/color selector (`lAxmS`): 32-icon grid (component `Icon Tile`)
/// + 7 pastel color swatches, no search field — both grids scroll within a
/// bounded viewport (`clip:true`, same pattern as the parent picker).
///
/// There is no separate "Confirm" button: the sheet stays open while the
/// user explores both grids and only closes through the app bar's
/// check/close, mirrored here as explicit Guardar/Cancelar actions since,
/// unlike the parent picker, two independent choices (icon + color) need to
/// be made before the pick is meaningful.
class IconColorPickerSheet extends StatefulWidget {
  const IconColorPickerSheet({
    this.initialIcon,
    this.initialColor,
    this.colorLocked = false,
    super.key,
  });

  final String? initialIcon;
  final String? initialColor;

  /// Subcategories inherit their parent's color and can't change it: the
  /// color grid renders disabled (`nqoD6`), with a lock icon inline next to
  /// the "Color" section label — same pattern the "Tipo" toggle already uses
  /// — while the icon grid above stays fully interactive.
  final bool colorLocked;

  static Future<CategoryAppearancePick?> show(
    BuildContext context, {
    String? initialIcon,
    String? initialColor,
    bool colorLocked = false,
  }) =>
      BottomSheetBase.show<CategoryAppearancePick>(
        context,
        builder: (context) => IconColorPickerSheet(
          initialIcon: initialIcon,
          initialColor: initialColor,
          colorLocked: colorLocked,
        ),
      );

  @override
  State<IconColorPickerSheet> createState() => _IconColorPickerSheetState();
}

class _IconColorPickerSheetState extends State<IconColorPickerSheet> {
  late String _icon = widget.initialIcon ?? CategoryAppearance.iconNames.first;
  late String _color =
      widget.initialColor ?? CategoryAppearance.colorTokens.first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.categoryAppearancePickerTitle,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (widget.colorLocked) ...[
          const SizedBox(height: 4),
          Text(
            l10n.categoryColorLockedSubcategory,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.categoryAppearanceIconSectionLabel,
          // `Section Label` (`O1HK1l`) is 600, not the baseline 500.
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 320,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: CategoryAppearance.iconNames.length,
            itemBuilder: (context, index) {
              final name = CategoryAppearance.iconNames[index];
              return IconTile(
                iconName: name,
                selected: name == _icon,
                selectedColorToken: _color,
                onTap: () => setState(() => _icon = name),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              l10n.categoryAppearanceColorSectionLabel,
              // `Section Label` (`QelD2`) is 600, not the baseline 500.
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.colorLocked) ...[
              const SizedBox(width: 6),
              Icon(LucideIcons.lock, size: 13, color: colors.textSecondary),
            ],
          ],
        ),
        if (!widget.colorLocked) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 58,
            runSpacing: 16,
            children: [
              for (final token in CategoryAppearance.colorTokens)
                CategoryColorSwatch(
                  token: token,
                  selected: token == _color,
                  onTap: () => setState(() => _color = token),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop((icon: _icon, color: _color)),
                child: Text(l10n.commonSave),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CategoryColorSwatch extends StatelessWidget {
  const CategoryColorSwatch({
    required this.token,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String token;
  final bool selected;

  /// `null` disables the swatch (color locked on a subcategory).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strong = CategoryAppearance.colorFor(colors, token);
    final soft = CategoryAppearance.softColorFor(colors, token);

    return Semantics(
      button: true,
      selected: selected,
      label: token,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: soft,
            shape: BoxShape.circle,
            border: selected ? Border.all(color: strong, width: 1.5) : null,
          ),
          child: selected
              ? Icon(LucideIcons.check, size: 18, color: strong)
              : Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: strong, shape: BoxShape.circle),
                  ),
                ),
        ),
      ),
    );
  }
}
