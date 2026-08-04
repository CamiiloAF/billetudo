import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../di/injection.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/bottom_sheet_base.dart';
import '../../../../widgets/sheet_buttons_row.dart';
import '../../cubit/sync_log_cubit.dart';
import '../../cubit/sync_log_state.dart';

/// "Registro técnico" (`T7Iw0C`): the **only** surface in the product where
/// raw sync vocabulary appears — codes, table names, ISO timestamps.
///
/// Its reader is support, not the user, which is why the block is styled like
/// a console (`$muted`, 11px) instead of like app content, and why it has to
/// be copyable. The privacy strip below states what the log does not carry, so
/// copying it does not feel like handing over one's finances.
class SyncLogSheet extends StatelessWidget {
  const SyncLogSheet({super.key});

  static Future<void> show(BuildContext context) => BottomSheetBase.show<void>(
        context,
        builder: (context) => BlocProvider(
          create: (context) {
            final cubit = getIt<SyncLogCubit>();
            unawaited(cubit.start());
            return cubit;
          },
          child: const SyncLogSheet(),
        ),
      );

  Future<void> _copy(BuildContext context) async {
    final cubit = context.read<SyncLogCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final text = await cubit.exportAsText();
    if (text == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.syncLogCopied)));
  }

  /// Hands the log to the system share sheet — the point of this screen is
  /// getting the log to whoever can read it, and the clipboard only covers the
  /// case where the user pastes it somewhere themselves.
  ///
  /// No snackbar afterwards: the share sheet is its own feedback, and the user
  /// may well dismiss it without picking a target.
  Future<void> _share(BuildContext context) async {
    final cubit = context.read<SyncLogCubit>();
    final l10n = AppLocalizations.of(context);
    final text = await cubit.exportAsText();
    if (text == null) {
      return;
    }
    await SharePlus.instance.share(
      ShareParams(text: text, subject: l10n.syncLogShareSubject),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<SyncLogCubit, SyncLogState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.muted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.fileText,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.syncTechnicalLogTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.syncLogSheetSubtitle(state.entries.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(AppTheme.radiusField),
              ),
              padding: const EdgeInsets.all(14),
              child: state.entries.isEmpty
                  ? Text(
                      l10n.syncLogEmpty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.entries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 7),
                      itemBuilder: (context, index) => Text(
                        state.entries[index].toLogLine(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(AppTheme.radiusField),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              child: Row(
                children: [
                  Icon(LucideIcons.lock, size: 16, color: colors.textPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.syncLogPrivacyNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // "Compartir" is the primary of the pair: this sheet exists so the
            // log reaches whoever can read it, and the share sheet is the only
            // path that does not depend on the user pasting it somewhere.
            SheetButtonsRow(
              left: OutlinedButton.icon(
                onPressed: () => unawaited(_copy(context)),
                icon: const Icon(LucideIcons.copy, size: 18),
                label: Text(l10n.syncLogCopy),
              ),
              right: FilledButton.icon(
                onPressed: () => unawaited(_share(context)),
                icon: const Icon(LucideIcons.share2, size: 18),
                label: Text(l10n.syncLogShare),
              ),
            ),
          ],
        );
      },
    );
  }
}
