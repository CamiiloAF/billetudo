import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../cubit/account_filter_cubit.dart';

/// HU-06a: multiple-selection bottom sheet over the live account list, with
/// "Todas"/"Ninguna" and an explicit "Aplicar" — dismissing without it
/// discards every change.
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
                  child: Text(
                    l10n.accountFilterSheetTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: cubit.selectAll,
                  child: Text(l10n.accountFilterSelectAll),
                ),
                TextButton(
                  onPressed: cubit.selectNone,
                  child: Text(l10n.accountFilterSelectNone),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in state.accounts)
                    CheckboxListTile(
                      value: state.selected.contains(entry.account.id),
                      onChanged: (_) => cubit.toggle(entry.account.id),
                      title: Text(entry.account.name),
                      subtitle: Text(
                        const MoneyFormatter().format(
                          entry.balance.balanceMinor,
                          currencyCode: entry.account.currency,
                        ),
                      ),
                    ),
                ],
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
