import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../domain/entities/category.dart';
import '../cubit/parent_category_picker_cubit.dart';
import '../cubit/parent_category_picker_state.dart';
import 'parent_category_row.dart';

/// The category picker sheet (`Q55fEz`): tap-to-choose-and-close, no
/// "Confirm" button — same pattern as Cuentas' currency picker.
///
/// Reused for both the subcategory form's "Categoría padre" field
/// ([rootsOnly] `true`, the default) and HU-04's "Reasignar a otra
/// categoría"/"Reasignar subcategorías" pickers.
class ParentCategoryPickerSheet extends StatelessWidget {
  const ParentCategoryPickerSheet({
    required this.kind,
    this.excludingId,
    this.selectedId,
    this.rootsOnly = true,
    this.title,
    super.key,
  });

  final CategoryKind kind;
  final String? excludingId;
  final String? selectedId;
  final bool rootsOnly;
  final String? title;

  /// Resolves to the picked [Category], or `null` if dismissed.
  static Future<Category?> show(
    BuildContext context, {
    required CategoryKind kind,
    String? excludingId,
    String? selectedId,
    bool rootsOnly = true,
    String? title,
  }) =>
      BottomSheetBase.show<Category>(
        context,
        builder: (context) => ParentCategoryPickerSheet(
          kind: kind,
          excludingId: excludingId,
          selectedId: selectedId,
          rootsOnly: rootsOnly,
          title: title,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<ParentCategoryPickerCubit>();
        unawaited(
          cubit.start(
            kind,
            excludingId: excludingId,
            selectedId: selectedId,
            rootsOnly: rootsOnly,
          ),
        );
        return cubit;
      },
      child: ParentCategoryPickerSheetBody(title: title),
    );
  }
}

class ParentCategoryPickerSheetBody extends StatelessWidget {
  const ParentCategoryPickerSheetBody({this.title, super.key});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? l10n.categoryParentPickerTitle,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child:
              BlocBuilder<ParentCategoryPickerCubit, ParentCategoryPickerState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.candidates.isEmpty) {
                return Center(
                  child: Text(
                    l10n.categoryParentPickerEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: state.candidates.length,
                itemBuilder: (context, index) {
                  final category = state.candidates[index];
                  return ParentCategoryRow(
                    category: category,
                    selected: category.id == state.selectedId,
                    onTap: () => Navigator.of(context).pop(category),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
