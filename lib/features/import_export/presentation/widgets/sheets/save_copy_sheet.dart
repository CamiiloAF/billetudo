import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../cubit/save_copy_cubit.dart';
import '../../cubit/save_copy_state.dart';
import '../blocking_progress_view.dart';
import '../io_error_view.dart';

/// HU-03/HU-09 "Guardar una copia": the whole flow is the shared blocking
/// progress/error pattern (`d9wzVg`-pattern with `$teal`, `TmHSC`/`HbEJc`) —
/// `Bottom Sheet Base` (`PqTUt`) in `billetudo.pen`, never a page with its
/// own `Page Header` (there is no separate "form" step to keep as a page,
/// unlike Export/Import). Triggered straight from the hub, same shape as
/// `RestoreSheet.show`.
class SaveCopySheet {
  const SaveCopySheet._();

  static Future<void> show(BuildContext context) async {
    final cubit = getIt<SaveCopyCubit>();
    unawaited(cubit.start());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      // Not casually dismissible while running (HU-03/HU-09: the only way
      // out mid-write is "Cancelar", which also deletes the partial file).
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BlocProvider<SaveCopyCubit>.value(
        value: cubit,
        child: const BottomSheetBase(child: SaveCopySheetBody()),
      ),
    );
    await cubit.close();
  }
}

/// The sheet's content for the current [SaveCopyState]: progress while
/// `running`, the write-failure pattern on `error`. `done`/`cancelled` never
/// render — they close the sheet instead (handing off to the share sheet, or
/// just backing out).
class SaveCopySheetBody extends StatelessWidget {
  const SaveCopySheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SaveCopyCubit, SaveCopyState>(
      listenWhen: (previous, current) =>
          previous.resultFilePath != current.resultFilePath ||
          previous.status != current.status,
      listener: (context, state) {
        if (state.resultFilePath case final path?) {
          unawaited(context.read<SaveCopyCubit>().shareResult(path));
          return;
        }
        if (state.status == SaveCopyStatus.idle ||
            state.status == SaveCopyStatus.cancelled) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final colors = context.colors;

        if (state.status == SaveCopyStatus.error) {
          return IntrinsicHeight(
            child: IoErrorView(
              icon: IoErrorIcons.writeFailure,
              title: l10n.importExportIoErrorWriteTitle,
              message: l10n.importExportIoErrorWriteBody,
              actionLabel: l10n.commonRetry,
              actionIcon: IoErrorIcons.retry,
              onAction: () => context.read<SaveCopyCubit>().start(),
              onCancel: () => Navigator.of(context).pop(),
            ),
          );
        }
        return IntrinsicHeight(
          child: BlockingProgressView(
            icon: LucideIcons.shieldCheck,
            iconColor: colors.teal,
            iconBackground: colors.tealSoft,
            title: l10n.importExportProgressSavingCopyTitle,
            processed: state.processed,
            total: state.total,
            onCancel: () => context.read<SaveCopyCubit>().cancel(),
          ),
        );
      },
    );
  }
}
