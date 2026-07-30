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
import '../pages/import_summary_step.dart';
import 'blocking_progress_view.dart';
import 'io_error_view.dart';

/// The body of `ImportFlowPage` for the current [ImportFlowState] — routes
/// to the right wizard step, the error state or the blocking progress view.
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

    if (state.runStatus == ImportFlowRunStatus.error) {
      return IoErrorView(
        icon: IoErrorIcons.unreadableFile,
        title: l10n.importExportIoErrorUnreadableTitle,
        message: l10n.importExportIoErrorUnreadableBody,
        actionLabel: l10n.importExportChooseAnotherFile,
        actionIcon: IoErrorIcons.chooseAnotherFile,
        onAction: cubit.dismissError,
        onCancel: onDone,
      );
    }
    if (state.isWorking) {
      final committing = state.runStatus == ImportFlowRunStatus.committing;
      return BlockingProgressView(
        icon: LucideIcons.fileInput,
        iconColor: colors.mint,
        iconBackground: colors.mintSoft,
        title: l10n.importExportProgressImportingTitle,
        processed: committing ? state.processed : 0,
        total: committing ? state.total : 0,
        onCancel: committing ? cubit.cancel : null,
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
          mapping: state.mapping,
          matchedTemplateName: state.matchedTemplateName,
          onFieldChanged: cubit.setFieldForColumn,
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
          onConfirm: cubit.confirm,
        );
      case ImportFlowStep.summary:
        final summary = state.summary;
        if (summary == null) {
          return const SizedBox.shrink();
        }
        return ImportSummaryStep(summary: summary, onDone: onDone);
    }
  }
}
