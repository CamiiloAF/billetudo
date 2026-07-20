import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../domain/entities/local_data_choice.dart';
import '../../cubit/delete_account_cubit.dart';
import '../../cubit/delete_account_state.dart';
import 'local_data_choice_row.dart';

/// HU-07 paso 2 (`K8SAG`): what to do with this device's data once the cloud
/// account is already gone. Both options carry equal visual weight and
/// **neither is preselected** — the CTA stays disabled until the user picks
/// one explicitly (no dark pattern).
///
/// Closes itself once the cubit reaches `done`.
class LocalDataChoiceSheet extends StatelessWidget {
  const LocalDataChoiceSheet({super.key});

  static Future<void> show(BuildContext context, DeleteAccountCubit cubit) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BlocProvider.value(
          value: cubit,
          child: BlocListener<DeleteAccountCubit, DeleteAccountState>(
            listenWhen: (previous, current) =>
                current.step == DeleteAccountStep.done,
            listener: (context, state) => Navigator.of(context).pop(),
            child: const LocalDataChoiceSheet(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return BlocBuilder<DeleteAccountCubit, DeleteAccountState>(
      builder: (context, state) {
        final cubit = context.read<DeleteAccountCubit>();
        final isLoading = state.status == DeleteAccountStatus.loading;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // `K8SAG`'s header (`zLjcF`) is a `Sheet Icon Header`: a 56px
            // `$primary-soft` circle with the `phone` glyph in
            // `$primary-on-soft`, a centred 17/700 title and a centred 14
            // `$text-secondary` subtitle — same treatment as Cerrar sesión,
            // not a left-aligned `SheetHead`.
            SheetMessage(
              icon: LucideIcons.phone,
              iconColor: colors.primaryOnSoft,
              iconBackground: colors.primarySoft,
              title: l10n.authDeleteStep2Title,
              message: l10n.authDeleteStep2Subtitle,
              messageColor: colors.textSecondary,
              messageFontSize: 14,
            ),
            const SizedBox(height: 20),
            LocalDataChoiceRow(
              title: l10n.authDeleteStep2KeepTitle,
              subtitle: l10n.authDeleteStep2KeepSubtitle,
              selected: state.choice == LocalDataChoice.keep,
              onTap: isLoading
                  ? null
                  : () => cubit.selectLocalDataChoice(LocalDataChoice.keep),
            ),
            const SizedBox(height: 12),
            LocalDataChoiceRow(
              title: l10n.authDeleteStep2DeleteTitle,
              subtitle: l10n.authDeleteStep2DeleteSubtitle,
              selected: state.choice == LocalDataChoice.delete,
              onTap: isLoading
                  ? null
                  : () => cubit.selectLocalDataChoice(LocalDataChoice.delete),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                // Disabled keeps the brand violet at 0.4 opacity (`GamyH` in
                // billetudo.pen), the same pattern Cuentas uses, instead of
                // Material's default grey.
                style: FilledButton.styleFrom(
                  disabledBackgroundColor:
                      colors.primary.withValues(alpha: 0.4),
                  disabledForegroundColor:
                      colors.onPrimary.withValues(alpha: 0.4),
                ),
                onPressed: !state.canContinueFromChoice || isLoading
                    ? null
                    : cubit.confirmLocalDataChoice,
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    // `lsZwE` renders the CTA as a `Button/Primary` with the
                    // `arrow-right` glyph (18px) to the left of "Continuar",
                    // same icon-left treatment as merge_confirmation's CTA.
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.arrowRight, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.authDeleteStep2Cta),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
