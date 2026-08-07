import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/import_flow_cubit.dart';
import '../cubit/import_flow_state.dart';
import '../pages/import_destinations_step.dart';
import '../pages/import_file_select_step.dart';
import '../pages/import_mapping_step.dart';
import '../pages/import_preview_step.dart';
import 'blocking_progress_view.dart';
import 'io_error_view.dart';
import 'sheets/import_run_sheet.dart';

/// The body of `ImportFlowPage` for the current [ImportFlowState] — routes
/// to the right wizard step (mapping/destinations/preview, each its own
/// full page under `jfq0l`/`pjdLI`) or the lightweight loading spinner
/// between them.
///
/// The final commit and what follows it — blocking progress, a write
/// failure or the closing summary (`d9wzVg`/`TmHSC`/`Aa1ek`) — are not
/// rendered here: they are `Bottom Sheet Base` in `billetudo.pen`
/// (`ImportRunSheet`, opened by the preview step's "Importar" tap), not
/// this page's body.
class ImportFlowBody extends StatelessWidget {
  const ImportFlowBody({
    required this.state,
    required this.cubit,
    required this.onDone,
    super.key,
  });

  final ImportFlowState state;
  final ImportFlowCubit cubit;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    // `committing`'s error lands here with `step` still `preview` (the only
    // point in the wizard that call happens from) — that one is
    // `ImportRunSheet`'s to show, already open when it occurs. Every other
    // error (the initial file parse, or the quick preview-generation calls
    // below) still renders inline on this page.
    if (state.runStatus == ImportFlowRunStatus.error &&
        state.step != ImportFlowStep.preview) {
      return IoErrorView(
        icon: IoErrorIcons.unreadableFile,
        title: l10n.importExportIoErrorUnreadableTitle,
        message: l10n.importExportIoErrorUnreadableBody,
        actionLabel: l10n.importExportChooseAnotherFile,
        actionIcon: IoErrorIcons.chooseAnotherFile,
        onAction: cubit.dismissError,
        onCancel: onDone,
        stackButtons: true,
      );
    }
    if (state.runStatus == ImportFlowRunStatus.working) {
      return BlockingProgressView(
        icon: LucideIcons.fileInput,
        iconColor: colors.mint,
        iconBackground: colors.mintSoft,
        title: l10n.importExportProgressImportingTitle,
        processed: 0,
        total: 0,
      );
    }

    switch (state.step) {
      case ImportFlowStep.fileSelect:
        // `ImportFlowPage` renders the entry step's own scrim/sheet chrome
        // and never delegates to this body while idle on this step.
        return const SizedBox.shrink();
      case ImportFlowStep.mapping:
        final sample = state.sample;
        if (sample == null) {
          return ImportFileSelectStep(onPickFile: cubit.pickFile, onCancel: onDone);
        }
        return ImportMappingStep(
          sample: sample,
          dialect: state.dialect,
          mapping: state.mapping,
          mappingMode: state.mappingMode,
          matchedTemplateName: state.matchedTemplateName,
          onMappingModeChanged: cubit.setMappingMode,
          onFieldChanged: cubit.setFieldForColumn,
          onDateFormatChanged: cubit.applyDateFormat,
          onDecimalConventionChanged: cubit.applyDecimalConvention,
          onTypeColumnChanged: cubit.applyTypeColumn,
          onAmountSignModeChanged: cubit.applyAmountSignMode,
          onConfirm: cubit.confirmMapping,
        );
      case ImportFlowStep.destinations:
        final preview = state.preview;
        if (preview == null) {
          return const SizedBox.shrink();
        }
        return ImportDestinationsStep(
          preview: preview,
          accountOverrides: state.accountOverrides,
          categoryOverrides: state.categoryOverrides,
          subcategoryOverrides: state.subcategoryOverrides,
          tagOverrides: state.tagOverrides,
          onAccountOverride: cubit.setAccountOverride,
          onCategoryOverride: cubit.setCategoryOverride,
          onSubcategoryOverride: cubit.setSubcategoryOverride,
          onTagOverride: cubit.setTagOverride,
          loadExistingAccounts: cubit.loadExistingAccounts,
          loadExistingRootCategories: cubit.loadExistingRootCategories,
          loadExistingSubcategories: cubit.loadExistingSubcategories,
          loadExistingTags: cubit.loadExistingTags,
          onConfirm: cubit.confirmDestinations,
          onReviewMapping: () => cubit.goToStep(ImportFlowStep.mapping),
        );
      case ImportFlowStep.preview:
        final preview = state.preview;
        if (preview == null) {
          return const SizedBox.shrink();
        }
        return ImportPreviewStep(
          preview: preview,
          includedRowNumbers: state.includedRowNumbers,
          onToggleRow: cubit.toggleRow,
          onIncludeAllDuplicates: cubit.includeAllDuplicates,
          onOmitAllDuplicates: cubit.omitAllDuplicates,
          onConfirm: ({saveTemplateAs}) => unawaited(
            ImportRunSheet.show(
              context,
              cubit: cubit,
              onDone: onDone,
              saveTemplateAs: saveTemplateAs,
            ),
          ),
        );
      case ImportFlowStep.summary:
        // `ImportRunSheet` (opened by the preview step's "Importar" tap)
        // owns the closing summary — the page underneath keeps whatever it
        // last rendered (`preview`, the step `confirm` never leaves) while
        // it's covered by the sheet's scrim.
        return const SizedBox.shrink();
    }
  }
}
