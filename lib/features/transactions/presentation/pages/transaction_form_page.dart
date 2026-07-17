import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/accounts_list_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_list_state.dart';
import '../../../accounts/presentation/widgets/account_select_row.dart';
import '../../../accounts/presentation/widgets/account_type_avatar.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/transaction_form_cubit.dart';
import '../cubit/transaction_form_state.dart';
import '../widgets/category_picker/category_quick_picker.dart';
import '../widgets/sheets/edit_impact_warning_sheet.dart';
import '../widgets/transaction_amount_fixed_zone.dart';
import '../widgets/transaction_date_field.dart';
import '../widgets/transaction_form_field_button.dart';
import '../widgets/transaction_info_box.dart';
import '../widgets/transaction_note_field.dart';
import '../widgets/transaction_tags_field.dart';
import '../widgets/transaction_type_segmented_control.dart';

/// HU-01/02/03/04: the single add/edit form, parametrized by
/// [TransactionFormState.type]. The scroll zone holds the selectors
/// (Segmented Control -> Cuenta(s) -> Categoría -> Fecha -> Nota -> Etiquetas);
/// the amount lives in the anchored Zona Fija at the bottom.
class TransactionFormPage extends StatelessWidget {
  const TransactionFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionFormCubit, TransactionFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.editImpact != current.editImpact,
      listener: (context, state) async {
        if (state.status == TransactionFormStatus.saved) {
          Navigator.of(context).pop();
          return;
        }
        final impact = state.editImpact;
        if (impact != null && impact.hasImpact) {
          final cubit = context.read<TransactionFormCubit>();
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (context) => EditImpactWarningSheet(
              impact: impact,
              onCancel: () {
                cubit.editImpactDismissed();
                Navigator.of(context).pop();
              },
              onConfirm: () {
                Navigator.of(context).pop();
                unawaited(cubit.submit(confirmed: true));
              },
            ),
          );
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final cubit = context.read<TransactionFormCubit>();
        final colors = context.colors;
        return Scaffold(
          appBar: AppBar(
            leadingWidth: 60,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: TransactionHeaderButton(
                icon: LucideIcons.x,
                background: colors.muted,
                foreground: colors.textPrimary,
                tooltip: l10n.commonCancel,
                onPressed: Navigator.of(context).pop,
              ),
            ),
            title: Text(
              _titleFor(l10n, state),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TransactionHeaderButton(
                  icon: LucideIcons.check,
                  background: colors.primary,
                  foreground: colors.onPrimary,
                  tooltip: l10n.commonSave,
                  onPressed: state.status == TransactionFormStatus.saving
                      ? null
                      : cubit.submit,
                ),
              ),
            ],
          ),
          body: state.status == TransactionFormStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: TransactionFormScrollZone(state: state),
                      ),
                      TransactionAmountFixedZone(
                        type: state.type,
                        amountMinor: state.amountMinor,
                        currency: state.currency,
                        expanded: state.isKeypadVisible,
                        onExpand: cubit.amountFocused,
                        onCollapse: cubit.fieldBlurred,
                        onDigit: cubit.amountDigitPressed,
                        onDecimal: cubit.amountDecimalPressed,
                        onOperator: cubit.amountOperatorPressed,
                        onEquals: cubit.amountEqualsPressed,
                        onBackspace: cubit.amountBackspace,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  String _titleFor(AppLocalizations l10n, TransactionFormState state) {
    if (state.isEditing) {
      return l10n.transactionFormEditTitle;
    }
    return switch (state.type) {
      TransactionType.expense => l10n.transactionFormNewExpenseTitle,
      TransactionType.income => l10n.transactionFormNewIncomeTitle,
      TransactionType.transfer => l10n.transactionFormNewTransferTitle,
    };
  }
}

/// The scrollable selectors of the form — everything but the anchored amount
/// zone. Order and per-type differences follow `transacciones.md`.
class TransactionFormScrollZone extends StatelessWidget {
  const TransactionFormScrollZone({required this.state, super.key});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TransactionFormCubit>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      children: [
        TransactionTypeSegmentedControl(
          type: state.type,
          onChanged: cubit.typeSelected,
        ),
        const SizedBox(height: 8),
        if (state.isTransfer) ...[
          TransferAccountsGroup(state: state),
          const SizedBox(height: 8),
          TransactionInfoBox(message: l10n.transactionFormTransferInfo),
        ] else ...[
          AccountPickerField(
            label: l10n.transactionFormAccountLabel,
            selectedId: state.accountId,
            selectedName: state.accountName,
            onSelected: cubit.accountSelected,
          ),
          const SizedBox(height: 8),
          CategoryQuickPicker(
            kind: state.type == TransactionType.income
                ? CategoryKind.income
                : CategoryKind.expense,
            selectedId: state.categoryId,
            onSelected: (category) => cubit.categorySelected(
              category.id,
              category.kind,
              category.name,
            ),
          ),
        ],
        const SizedBox(height: 8),
        TransactionDateField(date: state.date, onChanged: cubit.dateChanged),
        const SizedBox(height: 8),
        TransactionNoteField(
          initialNote: state.note,
          amountHasFocus: state.isKeypadVisible,
          onChanged: cubit.noteChanged,
          onFocused: cubit.noteFocused,
        ),
        if (!state.isTransfer) ...[
          const SizedBox(height: 8),
          TransactionTagsField(
            selectedIds: state.tagIds,
            onChanged: cubit.tagsChanged,
          ),
        ],
      ],
    );
  }
}

/// The transfer's origin/destination accounts plus the swap button, grouped
/// compactly so they read as one block (`Account Swap Group`).
///
/// Hosts a read-only [AccountsListCubit] purely so each account field can prefix
/// its value with the picked account's **type** icon (`nM9ea`) — composing
/// another feature's presentation for display is fine; only reaching into its
/// data/domain internals is not.
class TransferAccountsGroup extends StatelessWidget {
  const TransferAccountsGroup({required this.state, super.key});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          _started(getIt<AccountsListCubit>(), (c) => c.start()),
      child: TransferAccountsGroupBody(state: state),
    );
  }
}

class TransferAccountsGroupBody extends StatelessWidget {
  const TransferAccountsGroupBody({required this.state, super.key});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TransactionFormCubit>();
    final canSwap = state.accountId != null &&
        state.accountName != null &&
        state.transferAccountId != null &&
        state.transferAccountName != null;
    return BlocBuilder<AccountsListCubit, AccountsListState>(
      builder: (context, accountsState) {
        final iconByAccountId = <String, IconData>{
          for (final entry in accountsState.accounts)
            entry.account.id: entry.account.type.icon,
        };
        return Column(
          children: [
            AccountPickerField(
              label: l10n.transactionFormTransferFromLabel,
              selectedId: state.accountId,
              selectedName: state.accountName,
              onSelected: cubit.accountSelected,
              excludingId: state.transferAccountId,
              inlineIcon: iconByAccountId[state.accountId],
            ),
            const SizedBox(height: 4),
            Align(
              child: TransactionSwapButton(
                enabled: canSwap,
                onSwap: () {
                  final fromId = state.accountId!;
                  final fromName = state.accountName!;
                  final toId = state.transferAccountId!;
                  final toName = state.transferAccountName!;
                  cubit.accountSelected(toId, toName);
                  cubit.transferAccountSelected(fromId, fromName);
                },
              ),
            ),
            const SizedBox(height: 4),
            AccountPickerField(
              label: l10n.transactionFormTransferAccountLabel,
              selectedId: state.transferAccountId,
              selectedName: state.transferAccountName,
              onSelected: cubit.transferAccountSelected,
              excludingId: state.accountId,
              inlineIcon: iconByAccountId[state.transferAccountId],
            ),
          ],
        );
      },
    );
  }
}

/// The circular swap button between the two transfer accounts (`uL7Ux`): a
/// centered 44x44 `muted` wrap with the brand `arrow-down-up`. Greys out while
/// both accounts are not yet picked.
class TransactionSwapButton extends StatelessWidget {
  const TransactionSwapButton({
    required this.enabled,
    required this.onSwap,
    super.key,
  });

  final bool enabled;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Material(
      color: colors.muted,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onSwap : null,
        borderRadius: BorderRadius.circular(18),
        child: Tooltip(
          message: l10n.transactionFormSwapAccounts,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              LucideIcons.arrowDownUp,
              size: 20,
              color: enabled ? colors.primary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A circular 44x44 action button of the form's page header (`Dtm0X`): a filled
/// wrap with a single 18px icon. The back button uses `muted`, the save action
/// `primary`.
class TransactionHeaderButton extends StatelessWidget {
  const TransactionHeaderButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String tooltip;

  /// Null disables the button (e.g. save while already saving).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 18, color: foreground),
          ),
        ),
      ),
    );
  }
}

/// A "pick from a bottom sheet" account field, styled as a `Form Field`.
/// Reuses the accounts feature's own `AccountsListCubit` — composing another
/// feature's presentation is fine; only reaching into its `data`/domain
/// internals is not.
class AccountPickerField extends StatelessWidget {
  const AccountPickerField({
    required this.label,
    required this.selectedId,
    required this.selectedName,
    required this.onSelected,
    this.excludingId,
    this.inlineIcon,
    super.key,
  });

  final String label;
  final String? selectedId;

  /// Rendered instead of the placeholder once a selection exists — without this
  /// the field never shows which account the user picked.
  final String? selectedName;

  final void Function(String id, String name) onSelected;
  final String? excludingId;

  /// The account type icon shown inline before the value. Only the transfer
  /// fields set it; Gasto/Ingreso Cuenta stays icon-less.
  final IconData? inlineIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TransactionFormFieldButton(
      label: label,
      value: selectedName ?? l10n.transactionFormAccountChoose,
      hasValue: selectedName != null,
      inlineIcon: selectedName != null ? inlineIcon : null,
      onTap: () async {
        final account = await BottomSheetBase.show<Account>(
          context,
          builder: (context) => BlocProvider(
            create: (context) =>
                _started(getIt<AccountsListCubit>(), (c) => c.start()),
            child: AccountPickerSheetBody(
              excludingId: excludingId,
              selectedId: selectedId,
            ),
          ),
        );
        if (account != null) {
          onSelected(account.id, account.name);
        }
      },
    );
  }
}

/// The account picker sheet body, on the shared `Bottom Sheet Base` chrome: a
/// centered "Elegir cuenta" title over the live account list, each row the
/// reusable [AccountSelectRow] (`Filter Account Row`, `X3tZG`) in single-select
/// — a tap picks the account and closes the sheet. The currently chosen
/// account ([selectedId]) is highlighted with its check.
class AccountPickerSheetBody extends StatelessWidget {
  const AccountPickerSheetBody({this.excludingId, this.selectedId, super.key});

  final String? excludingId;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AccountsListCubit, AccountsListState>(
      builder: (context, state) {
        final entries = [
          for (final entry in state.accounts)
            if (entry.account.id != excludingId) entry,
        ];
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.transactionFormAccountChoose,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return AccountSelectRow(
                      account: entry.account,
                      balance: entry.balance,
                      selected: entry.account.id == selectedId,
                      onTap: () => Navigator.of(context).pop(entry.account),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Kicks off a cubit's initial load without awaiting it (it emits its loading
/// state synchronously and the sheet renders it), and hands it straight to
/// `BlocProvider` — same pattern as `createAppRouter`'s own helper.
T _started<T>(T cubit, Future<void> Function(T cubit) start) {
  unawaited(start(cubit));
  return cubit;
}
