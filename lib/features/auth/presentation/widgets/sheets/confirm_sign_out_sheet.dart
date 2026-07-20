import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../../domain/entities/local_data_choice.dart';
import '../../cubit/sign_out_sheet_cubit.dart';
import '../../cubit/sign_out_sheet_state.dart';
import 'delete_opt_in_row.dart';
import 'unsynced_changes_warning.dart';

/// HU-06 (`wlVUL` / `c87DpD` / `dpxOS`): confirms signing out and lets the
/// user also wipe this phone's data.
///
/// The header stays neutral (`$primary-soft` / `log-out`) even with the
/// opt-in on — the base action is still signing out, not deleting an account.
/// What does change is the *message*: with the box ticked, promising the data
/// "seguirá guardada" would be literally false, 30px above a red row saying
/// the opposite.
///
/// Wiping is never blocked by a pending upload queue — a stuck sync (decisión
/// #17) must not trap the user's own data. It warns and respects the choice.
class ConfirmSignOutSheet extends StatelessWidget {
  const ConfirmSignOutSheet({super.key});

  /// Resolves to the user's choice, or `null` when they cancelled.
  static Future<LocalDataChoice?> show(
    BuildContext context,
    SignOutSheetCubit cubit,
  ) =>
      BottomSheetBase.show<LocalDataChoice>(
        context,
        builder: (context) => BlocProvider.value(
          value: cubit,
          child: const ConfirmSignOutSheet(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<SignOutSheetCubit, SignOutSheetState>(
      builder: (context, state) {
        final deleting = state.deleteLocalData;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetMessage(
              icon: LucideIcons.logOut,
              iconColor: colors.primaryOnSoft,
              iconBackground: colors.primarySoft,
              title: l10n.authSignOutSheetTitle,
              message: deleting
                  ? l10n.authSignOutSheetMessageDeleting
                  : l10n.authSignOutSheetMessage,
              messageColor: colors.textSecondary,
              messageFontSize: 14,
            ),
            const SizedBox(height: 16),
            DeleteOptInRow(
              title: l10n.authSignOutDeleteOptInTitle,
              subtitle: l10n.authSignOutDeleteOptInSubtitle,
              selected: deleting,
              onTap: context.read<SignOutSheetCubit>().toggleDeleteLocalData,
            ),
            if (state.showsUnsyncedWarning) ...[
              const SizedBox(height: 16),
              UnsyncedChangesWarning(
                title: l10n.authSignOutUnsyncedTitle,
                body: l10n.authSignOutUnsyncedBody(state.pendingUploadCount),
              ),
            ],
            const SizedBox(height: 16),
            SheetButtonsRow(
              left: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
              right: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(
                  deleting ? LocalDataChoice.delete : LocalDataChoice.keep,
                ),
                style: deleting
                    ? FilledButton.styleFrom(
                        backgroundColor: colors.expense,
                        foregroundColor: colors.onPrimary,
                      )
                    : null,
                icon: Icon(deleting ? LucideIcons.trash2 : LucideIcons.logOut),
                label: Text(
                  deleting ? l10n.authSignOutDeleteCta : l10n.authSignOutCta,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
