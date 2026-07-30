import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/save_copy_cubit.dart';
import '../cubit/save_copy_state.dart';
import '../widgets/blocking_progress_view.dart';
import '../widgets/io_error_view.dart';

/// HU-03 "Guardar una copia" — blocking progress, then the share sheet.
class SaveCopyPage extends StatelessWidget {
  const SaveCopyPage({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return BlocConsumer<SaveCopyCubit, SaveCopyState>(
      listenWhen: (previous, current) =>
          previous.resultFilePath != current.resultFilePath ||
          previous.status != current.status,
      listener: (context, state) {
        if (state.resultFilePath case final path?) {
          unawaited(
            context.read<SaveCopyCubit>().shareResult(path).then((_) {
              if (context.mounted) {
                onDone();
              }
            }),
          );
        } else if (state.status == SaveCopyStatus.cancelled) {
          // HU-03/HU-09: cancelling closes this screen the same way backing
          // out of "Guardar una copia" before starting would.
          onDone();
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: state.status != SaveCopyStatus.running,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  PageHeader(title: l10n.importExportSaveCopyCta),
                  Expanded(
                    child: switch (state.status) {
                      SaveCopyStatus.error => IoErrorView(
                          icon: IoErrorIcons.writeFailure,
                          title: l10n.importExportIoErrorWriteTitle,
                          message: l10n.importExportIoErrorWriteBody,
                          actionLabel: l10n.commonRetry,
                          actionIcon: IoErrorIcons.retry,
                          onAction: () => context.read<SaveCopyCubit>().start(),
                          onCancel: onDone,
                        ),
                      _ => BlockingProgressView(
                          icon: LucideIcons.shieldCheck,
                          iconColor: colors.teal,
                          iconBackground: colors.tealSoft,
                          title: l10n.importExportProgressSavingCopyTitle,
                          processed: state.processed,
                          total: state.total,
                          onCancel: () => context.read<SaveCopyCubit>().cancel(),
                        ),
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
