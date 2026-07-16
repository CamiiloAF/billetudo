import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
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
  const IconColorPickerSheet({this.initialIcon, this.initialColor, super.key});

  final String? initialIcon;
  final String? initialColor;

  static Future<CategoryAppearancePick?> show(
    BuildContext context, {
    String? initialIcon,
    String? initialColor,
  }) =>
      showModalBottomSheet<CategoryAppearancePick>(
        context: context,
        isScrollControlled: true,
        builder: (context) => IconColorPickerSheet(
          initialIcon: initialIcon,
          initialColor: initialColor,
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.categoryAppearancePickerTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
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
        ),
      ),
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
  final VoidCallback onTap;

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
