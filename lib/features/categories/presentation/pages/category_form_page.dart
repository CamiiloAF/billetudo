import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_draft.dart';
import '../cubit/category_form_cubit.dart';
import '../cubit/category_form_state.dart';
import '../widgets/appearance_field.dart';
import '../widgets/delete_link.dart';
import '../widgets/icon_color_picker_sheet.dart';
import '../widgets/parent_category_picker_sheet.dart';
import '../widgets/sheets/confirm_delete_root_with_subcategories_sheet.dart';
import '../widgets/sheets/confirm_delete_simple_sheet.dart';
import '../widgets/sheets/confirm_delete_with_transactions_sheet.dart';

/// The single add/edit form (`CuTjr`/`iUmrh`/`PZvWF`/`STIfS`).
///
/// Structure: Apariencia -> Nombre -> Tipo -> [Categoría padre] ->
/// Guardar/Eliminar. Which pieces show and whether Tipo is locked depends on
/// [CategoryFormState], not on which of the 4 cases the caller thinks it is
/// building — the state already encodes that.
class CategoryFormPage extends StatelessWidget {
  const CategoryFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryFormCubit, CategoryFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.deletePrompt != current.deletePrompt,
      listener: (context, state) async {
        if (state.status == CategoryFormStatus.saved) {
          Navigator.of(context).pop();
          return;
        }
        await _handlePrompt(context, state);
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: Navigator.of(context).pop,
              tooltip: l10n.commonCancel,
              icon: const Icon(LucideIcons.x),
            ),
            title: Text(_titleFor(l10n, state)),
            actions: [
              IconButton(
                onPressed: state.status == CategoryFormStatus.saving
                    ? null
                    : context.read<CategoryFormCubit>().submit,
                tooltip: l10n.commonSave,
                icon: const Icon(LucideIcons.check),
              ),
            ],
          ),
          body: SafeArea(
            child: state.status == CategoryFormStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : CategoryFormBody(state: state),
          ),
        );
      },
    );
  }

  String _titleFor(AppLocalizations l10n, CategoryFormState state) {
    if (!state.isEditing) {
      return state.isSubcategory
          ? l10n.categoryFormNewSubcategoryTitle
          : l10n.categoryFormNewTitle;
    }
    return state.isSubcategory
        ? l10n.categoryFormEditSubcategoryTitle
        : l10n.categoryFormEditTitle;
  }

  Future<void> _handlePrompt(
    BuildContext context,
    CategoryFormState state,
  ) async {
    final cubit = context.read<CategoryFormCubit>();
    switch (state.deletePrompt) {
      case CategoryDeletePrompt.none:
        return;
      case CategoryDeletePrompt.simple:
        final confirmed = await ConfirmDeleteSimpleSheet.show(
          context,
          budgetCount: state.deletionImpact?.budgetCount ?? 0,
          isSubcategory: state.isSubcategory,
        );
        if (confirmed ?? false) {
          await cubit.confirmSimpleDelete();
        } else {
          cubit.dismissDeletePrompt();
        }
      case CategoryDeletePrompt.transactions:
        final impact = state.deletionImpact;
        final resolution = await ConfirmDeleteWithTransactionsSheet.show(
          context,
          transactionCount: impact?.transactionCount ?? 0,
          kind: state.kind,
          excludingId: state.id!,
          budgetCount: impact?.budgetCount ?? 0,
        );
        if (resolution != null) {
          await cubit.confirmTransactionResolution(resolution);
        } else {
          cubit.dismissDeletePrompt();
        }
      case CategoryDeletePrompt.subcategories:
        final resolution = await ConfirmDeleteRootWithSubcategoriesSheet.show(
          context,
          kind: state.kind,
          rootId: state.id!,
          budgetCount: state.deletionImpact?.budgetCount ?? 0,
        );
        if (resolution != null) {
          await cubit.confirmSubcategoryResolution(resolution);
        } else {
          cubit.dismissDeletePrompt();
        }
    }
  }
}

/// The form's fields: Apariencia, Nombre, Tipo (locked or not) and, only for
/// a subcategory, Categoría padre.
class CategoryFormBody extends StatelessWidget {
  const CategoryFormBody({required this.state, super.key});

  final CategoryFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<CategoryFormCubit>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        AppearanceField(
          label: l10n.categoryFormAppearanceLabel,
          sublabel: state.icon == null
              ? l10n.categoryFormAppearanceEmptySublabel
              : l10n.categoryFormAppearanceFilledSublabel,
          iconName: state.icon,
          colorToken: state.color,
          onTap: () async {
            final picked = await IconColorPickerSheet.show(
              context,
              initialIcon: state.icon,
              initialColor: state.color,
            );
            if (picked != null) {
              cubit.appearanceSelected(icon: picked.icon, color: picked.color);
            }
          },
        ),
        const SizedBox(height: 18),
        Text(
          l10n.categoryFormNameLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: state.name,
          maxLength: CategoryDraft.maxNameLength,
          decoration: InputDecoration(
            hintText: l10n.categoryFormNameHint,
            counterText: '',
            errorText: _errorFor(l10n, state, CategoryDraft.fieldName),
          ),
          onChanged: cubit.nameChanged,
        ),
        const SizedBox(height: 18),
        Text(
          l10n.categoryFormKindLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        CategoryKindField(state: state, onChanged: cubit.kindSelected),
        if (state.isSubcategory) ...[
          const SizedBox(height: 18),
          Text(
            l10n.categoryFormParentLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          CategoryParentField(
            state: state,
            onTap: state.isEditing
                ? () async {
                    final picked = await ParentCategoryPickerSheet.show(
                      context,
                      kind: state.kind,
                      excludingId: state.id,
                      selectedId: state.parentId,
                    );
                    if (picked != null) {
                      cubit.parentSelected(picked);
                    }
                  }
                : null,
          ),
        ],
        if (state.isEditing) ...[
          const SizedBox(height: 28),
          DeleteLink(
            label: l10n.categoryDeleteAction,
            onTap: cubit.promptDelete,
          ),
        ],
      ],
    );
  }

  String? _errorFor(
    AppLocalizations l10n,
    CategoryFormState state,
    String field,
  ) {
    if (state.failedField != field) {
      return null;
    }
    return field == CategoryDraft.fieldName
        ? l10n.categoryErrorName
        : l10n.errorUnexpected;
  }
}

/// Tipo Gasto/Ingreso: a plain toggle, or the locked treatment (candado +
/// `opacity:0.55` + explanatory caption) per [CategoryFormState.kindLockReason].
class CategoryKindField extends StatelessWidget {
  const CategoryKindField(
      {required this.state, required this.onChanged, super.key});

  final CategoryFormState state;
  final ValueChanged<CategoryKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final toggle = Opacity(
      opacity: state.kindLocked ? 0.55 : 1,
      child: Row(
        children: [
          Expanded(
            child: CategoryKindOption(
              label: l10n.categoryKindExpense,
              selected: state.kind == CategoryKind.expense,
              enabled: !state.kindLocked,
              onTap: () => onChanged(CategoryKind.expense),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CategoryKindOption(
              label: l10n.categoryKindIncome,
              selected: state.kind == CategoryKind.income,
              enabled: !state.kindLocked,
              onTap: () => onChanged(CategoryKind.income),
            ),
          ),
        ],
      ),
    );

    if (!state.kindLocked) {
      return toggle;
    }

    final caption = state.kindLockReason == CategoryKindLockReason.subcategory
        ? l10n.categoryKindLockedSubcategory
        : l10n.categoryKindLockedRoot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        toggle,
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(LucideIcons.lock, size: 14, color: colors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                caption,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CategoryKindOption extends StatelessWidget {
  const CategoryKindOption({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primarySoft : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// The "Categoría padre" selector field: read-only (`$muted`, no chevron)
/// when creating (prefilled from "Agregar subcategoría"), tappable when
/// editing (reclassification, HU-03).
class CategoryParentField extends StatelessWidget {
  const CategoryParentField(
      {required this.state, required this.onTap, super.key});

  final CategoryFormState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final editable = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: editable ? colors.surface : colors.muted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                state.parentName ?? '',
                style: theme.textTheme.bodyLarge,
              ),
            ),
            if (editable)
              Icon(LucideIcons.chevronDown,
                  color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
