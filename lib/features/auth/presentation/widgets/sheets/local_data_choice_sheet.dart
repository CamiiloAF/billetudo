import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';
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
    final theme = Theme.of(context);

    return BlocBuilder<DeleteAccountCubit, DeleteAccountState>(
      builder: (context, state) {
        final cubit = context.read<DeleteAccountCubit>();
        final isLoading = state.status == DeleteAccountStatus.loading;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A sheet title is 17/700 in billetudo.pen (`lmN3k` in `K8SAG`'s
            // `Sheet Icon Header`), which is what `SheetHead` renders.
            SheetHead(title: l10n.authDeleteStep2Title),
            const SizedBox(height: 8),
            Text(
              l10n.authDeleteStep2Subtitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                onPressed: !state.canContinueFromChoice || isLoading
                    ? null
                    : cubit.confirmLocalDataChoice,
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.authDeleteStep2Cta),
              ),
            ),
          ],
        );
      },
    );
  }
}
