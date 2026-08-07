import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../cubit/import_flow_cubit.dart';
import '../../cubit/import_flow_state.dart';
import '../io_error_view.dart';

/// Entry point for HU-05 CSV import (`a5XdP`/`qWIvy`, decision 2026-08-07):
/// pick the CSV directly with the OS's native file picker — same pattern
/// already adopted for restore (`RestoreSheet`) — and, only if a file was
/// actually chosen, either hand a ready-to-go [ImportFlowCubit] back to the
/// caller (parsed fine, starting on the wizard's step 2/4 "mapping") or show
/// the unreadable-file error in its own modal sheet (`PqTUt`) first,
/// retrying with the same cubit until it either parses or the user cancels.
///
/// Never pushes a route itself — routing stays owned by `app_router.dart`
/// (same reason `AppRoutes` isn't referenced from `lib/features/`): callers
/// push `ImportFlowPage` with the returned cubit as `extra`, or do nothing
/// when this resolves to `null` (native picker backed out of, or the user
/// cancelled out of the error sheet).
class ImportPickSheet {
  const ImportPickSheet._();

  /// Returns the cubit to open the wizard with, or `null` if there is
  /// nothing to open (the caller is responsible for closing whichever cubit
  /// it ends up not using — same lifecycle `RestoreSheet.show` follows).
  static Future<ImportFlowCubit?> show(BuildContext context) async {
    final cubit = getIt<ImportFlowCubit>()..reset();
    await cubit.pickFile();
    if (cubit.state.step == ImportFlowStep.fileSelect &&
        cubit.state.runStatus == ImportFlowRunStatus.idle) {
      // The user backed out of the native picker without choosing a file —
      // nothing to show, so this never opens a dead sheet or a dead page.
      await cubit.close();
      return null;
    }
    if (!context.mounted) {
      await cubit.close();
      return null;
    }
    if (cubit.state.runStatus == ImportFlowRunStatus.error) {
      final parsedAfterRetry = await _showError(context, cubit);
      if (!parsedAfterRetry) {
        await cubit.close();
        return null;
      }
    }
    return cubit;
  }

  /// Shows the unreadable-file error sheet; returns whether a retry from
  /// inside it ended up parsing successfully (in which case the sheet closes
  /// itself so the caller can hand off to the wizard).
  static Future<bool> _showError(BuildContext context, ImportFlowCubit cubit) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetContext) => BlocProvider<ImportFlowCubit>.value(
        value: cubit,
        child: BottomSheetBase(
          child: ImportPickErrorSheetBody(
            onDismissed: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    );
    return cubit.state.step != ImportFlowStep.fileSelect;
  }
}

/// The unreadable-file error sheet's content (`a5XdP`/`qWIvy`): reads the
/// current [ImportFlowCubit] from context, same `IoErrorView` pattern
/// `RestoreSheetBody`'s `RestoreStep.error` case and `SaveCopySheetBody`'s
/// error case both already use. Split out from `ImportPickSheet._showError`
/// so it can be golden-tested directly, the same way `RestoreSheetBody` is.
class ImportPickErrorSheetBody extends StatelessWidget {
  const ImportPickErrorSheetBody({required this.onDismissed, super.key});

  /// Called once a retry from inside this sheet actually parses (so the
  /// caller can pop the modal route and hand off to the wizard) or the user
  /// taps "Cancelar".
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImportFlowCubit, ImportFlowState>(
      listener: (context, state) {
        // A retry ("Elegir otro archivo") that actually parses moves past
        // `fileSelect` — close this sheet so the caller can hand off to the
        // wizard instead of leaving the error still on screen.
        if (state.step != ImportFlowStep.fileSelect) {
          onDismissed();
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final cubit = context.read<ImportFlowCubit>();
        return IntrinsicHeight(
          child: IoErrorView(
            icon: IoErrorIcons.unreadableFile,
            title: l10n.importExportIoErrorUnreadableTitle,
            message: l10n.importExportIoErrorUnreadableBody,
            actionLabel: l10n.importExportChooseAnotherFile,
            actionIcon: IoErrorIcons.chooseAnotherFile,
            onAction: cubit.pickFile,
            onCancel: onDismissed,
            stackButtons: true,
          ),
        );
      },
    );
  }
}
