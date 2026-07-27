import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../../../../accounts/presentation/widgets/account_select_row.dart';
import '../../cubit/account_filter_cubit.dart';

/// HU-06a: multiple-selection bottom sheet over the live account list, with
/// "Todas" and an explicit "Aplicar" — dismissing without it discards every
/// change. There is deliberately no "Ninguna": clearing every account would
/// leave the list showing nothing, which is never useful.
class AccountFilterSheet extends StatelessWidget {
  const AccountFilterSheet({required this.initialSelected, super.key});

  final Set<String> initialSelected;

  /// Resolves to the applied selection, or `null` if dismissed without
  /// applying.
  static Future<Set<String>?> show(
    BuildContext context, {
    required Set<String> initialSelected,
  }) =>
      BottomSheetBase.show<Set<String>>(
        context,
        builder: (context) =>
            AccountFilterSheet(initialSelected: initialSelected),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<AccountFilterCubit>();
        unawaited(cubit.start(initialSelected));
        return cubit;
      },
      child: const AccountFilterSheetBody(),
    );
  }
}

/// The sheet's content, split out so it can `context.read` its own cubit.
class AccountFilterSheetBody extends StatelessWidget {
  const AccountFilterSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AccountFilterCubit, AccountFilterState>(
      builder: (context, state) {
        final cubit = context.read<AccountFilterCubit>();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  // A sheet title is 17/700 in billetudo.pen (`ElVUc` in
                  // `jpARf`), which is what `SheetHead` renders.
                  child: SheetHead(title: l10n.accountFilterSheetTitle),
                ),
                TextButton(
                  onPressed: cubit.selectAll,
                  child: Text(l10n.accountFilterSelectAll),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.accounts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = state.accounts[index];
                  return AccountSelectRow(
                    account: entry.account,
                    balance: entry.balance,
                    selected: state.selected.contains(entry.account.id),
                    onTap: () => cubit.toggle(entry.account.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(state.selected),
                child: Text(l10n.commonApply),
              ),
            ),
          ],
        );
      },
    );
  }
}
