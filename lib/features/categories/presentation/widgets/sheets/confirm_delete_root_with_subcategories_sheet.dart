import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/usecases/delete_category.dart';
import '../parent_category_picker_sheet.dart';

/// HU-04 case 3: a root with active subcategories (`w9ixr`).
///
/// The `info` icon (not a destructive one): this is a system restriction, not
/// a direct delete. Two navigational actions with different visual weight —
/// "Reasignar subcategorías" (`$primary-soft`, neutral) and "Eliminar todo en
/// cascada" (`$expense-soft`) — plus a single full-width Cancelar, since the
/// 2 real actions already live above. Cascade asks for a second, explicit
/// confirmation (`categorias.md`'s pending note: this action is broad and
/// deserves extra friction).
class ConfirmDeleteRootWithSubcategoriesSheet extends StatelessWidget {
  const ConfirmDeleteRootWithSubcategoriesSheet({
    required this.kind,
    required this.rootId,
    super.key,
  });

  final CategoryKind kind;
  final String rootId;

  /// Resolves to the chosen [SubcategoryResolution], or `null` if dismissed.
  static Future<SubcategoryResolution?> show(
    BuildContext context, {
    required CategoryKind kind,
    required String rootId,
  }) =>
      showModalBottomSheet<SubcategoryResolution>(
        context: context,
        isScrollControlled: true,
        builder: (context) => ConfirmDeleteRootWithSubcategoriesSheet(
          kind: kind,
          rootId: rootId,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child:
                  Icon(LucideIcons.info, color: colors.primaryOnSoft, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.categoryDeleteSubcategoriesTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.categoryDeleteSubcategoriesMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            CategoryDeleteActionRow(
              icon: LucideIcons.arrowLeftRight,
              label: l10n.categoryReassignSubcategoriesOption,
              background: colors.primarySoft,
              foreground: colors.primaryOnSoft,
              onTap: () async {
                final target = await ParentCategoryPickerSheet.show(
                  context,
                  kind: kind,
                  excludingId: rootId,
                  title: l10n.categoryReassignSubcategoriesPickerTitle,
                );
                if (target != null && context.mounted) {
                  Navigator.of(context)
                      .pop(SubcategoryResolution.reassign(target.id));
                }
              },
            ),
            const SizedBox(height: 12),
            CategoryDeleteActionRow(
              icon: LucideIcons.trash2,
              label: l10n.categoryCascadeDeleteOption,
              background: colors.expenseSoft,
              foreground: colors.expense,
              onTap: () async {
                final confirmed = await _confirmCascade(context, l10n);
                if ((confirmed ?? false) && context.mounted) {
                  Navigator.of(context)
                      .pop(const SubcategoryResolution.cascade());
                }
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmCascade(BuildContext context, AppLocalizations l10n) {
    final colors = context.colors;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.categoryCascadeConfirmTitle),
        content: Text(l10n.categoryCascadeConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.commonDelete,
              style: TextStyle(color: colors.expense),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDeleteActionRow extends StatelessWidget {
  const CategoryDeleteActionRow({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
