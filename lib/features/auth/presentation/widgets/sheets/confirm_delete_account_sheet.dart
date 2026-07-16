import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../cubit/delete_account_cubit.dart';
import '../../cubit/delete_account_state.dart';

/// HU-07 paso 1 (`j8ZdEx` confirm / `T1YkkA` error): the only genuinely
/// destructive sheet of this feature — `$expense` tone, irreversibility
/// spelled out plainly. Swaps in place to the neutral error variant
/// (`wifi-off`, "No pudimos eliminar tu cuenta") if [DeleteAccountCubit]
/// reports a failure, instead of stacking a second sheet.
///
/// Closes itself once the cubit advances past this step; the caller only
/// needs to await [show] and then read the cubit's state to decide what
/// comes next.
class ConfirmDeleteAccountSheet extends StatelessWidget {
  const ConfirmDeleteAccountSheet({super.key});

  static Future<void> show(BuildContext context, DeleteAccountCubit cubit) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BlocProvider.value(
          value: cubit,
          child: BlocListener<DeleteAccountCubit, DeleteAccountState>(
            listenWhen: (previous, current) =>
                current.step != DeleteAccountStep.confirm,
            listener: (context, state) => Navigator.of(context).pop(),
            child: const ConfirmDeleteAccountSheet(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<DeleteAccountCubit, DeleteAccountState>(
      builder: (context, state) {
        final cubit = context.read<DeleteAccountCubit>();
        final isLoading = state.status == DeleteAccountStatus.loading;
        final hasError = state.status == DeleteAccountStatus.error;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasError)
              SheetMessage(
                icon: LucideIcons.wifiOff,
                iconColor: colors.textSecondary,
                iconBackground: colors.muted,
                title: l10n.authDeleteStep1ErrorTitle,
                message: l10n.authDeleteStep1ErrorMessage,
              )
            else
              SheetMessage(
                icon: LucideIcons.triangleAlert,
                iconColor: colors.expense,
                iconBackground: colors.expenseSoft,
                title: l10n.authDeleteStep1Title,
                message: l10n.authDeleteStep1Message,
              ),
            const SizedBox(height: 24),
            SheetButtonsRow(
              left: OutlinedButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
              right: hasError
                  ? OutlinedButton.icon(
                      onPressed: isLoading ? null : cubit.retryDelete,
                      icon: const Icon(LucideIcons.refreshCw),
                      label: Text(l10n.commonRetry),
                    )
                  : FilledButton.icon(
                      onPressed: isLoading ? null : cubit.confirmDelete,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.expense,
                      ),
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.trash),
                      label: Text(l10n.authDeleteStep1Cta),
                    ),
            ),
          ],
        );
      },
    );
  }
}
