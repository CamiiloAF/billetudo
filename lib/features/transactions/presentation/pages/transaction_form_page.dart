import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/accounts_list_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_list_state.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/entities/category_node.dart';
import '../../../categories/presentation/cubit/categories_list_cubit.dart';
import '../../../categories/presentation/cubit/categories_list_state.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/transaction_form_cubit.dart';
import '../cubit/transaction_form_state.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/sheets/edit_impact_warning_sheet.dart';
import '../widgets/transaction_type_segmented_control.dart';

/// HU-01/02/03/04: the single add/edit form, parametrized by
/// [TransactionFormState.type]. Structure: Tipo -> Monto (con teclado
/// anclado) -> Cuenta(s) -> Categoría -> Fecha -> Nota -> Etiquetas.
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
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: Navigator.of(context).pop,
              tooltip: l10n.commonCancel,
              icon: const Icon(Icons.close),
            ),
            title: Text(_titleFor(l10n, state)),
            actions: [
              IconButton(
                onPressed: state.status == TransactionFormStatus.saving
                    ? null
                    : () => context.read<TransactionFormCubit>().submit(),
                tooltip: l10n.commonSave,
                icon: const Icon(Icons.check),
              ),
            ],
          ),
          body: SafeArea(
            child: state.status == TransactionFormStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      TransactionFormBody(state: state),
                      if (state.isKeypadVisible)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: NumericKeypad(
                            onDigit: context
                                .read<TransactionFormCubit>()
                                .amountDigitPressed,
                            onBackspace: context
                                .read<TransactionFormCubit>()
                                .amountBackspace,
                            onDone: context
                                .read<TransactionFormCubit>()
                                .fieldBlurred,
                          ),
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

/// The form's scrollable content: everything but the anchored keypad, so the
/// keypad can float above it without being pushed off-screen.
class TransactionFormBody extends StatelessWidget {
  const TransactionFormBody({required this.state, super.key});

  final TransactionFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TransactionFormCubit>();
    const money = MoneyFormatter();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 260),
      children: [
        TransactionTypeSegmentedControl(
            type: state.type, onChanged: cubit.typeSelected),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: cubit.amountFocused,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Text(
              money.formatAmount(state.amountMinor),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AccountPickerField(
          label: l10n.transactionFormAccountLabel,
          selectedId: state.accountId,
          selectedName: state.accountName,
          onSelected: cubit.accountSelected,
        ),
        if (state.isTransfer) ...[
          const SizedBox(height: 12),
          AccountPickerField(
            label: l10n.transactionFormTransferAccountLabel,
            selectedId: state.transferAccountId,
            selectedName: state.transferAccountName,
            onSelected: cubit.transferAccountSelected,
            excludingId: state.accountId,
          ),
        ] else ...[
          const SizedBox(height: 12),
          CategoryPickerField(
            kind: state.type == TransactionType.income
                ? CategoryKind.income
                : CategoryKind.expense,
            selectedId: state.categoryId,
            selectedName: state.categoryName,
            onSelected: cubit.categorySelected,
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(labelText: l10n.transactionFormNoteLabel),
          controller: TextEditingController(text: state.note)
            ..selection = TextSelection.collapsed(offset: state.note.length),
          onTap: cubit.noteFocused,
          onChanged: cubit.noteChanged,
        ),
      ],
    );
  }
}

/// A minimal "pick from a bottom sheet" account field. Reuses the accounts
/// feature's own `AccountsListCubit` — composing another feature's
/// presentation is fine; only reaching into its `data`/domain internals is
/// not.
class AccountPickerField extends StatelessWidget {
  const AccountPickerField({
    required this.label,
    required this.selectedId,
    required this.selectedName,
    required this.onSelected,
    this.excludingId,
    super.key,
  });

  final String label;
  final String? selectedId;

  /// Rendered instead of [label] once a selection exists — without this the
  /// button never shows which account the user picked.
  final String? selectedName;

  final void Function(String id, String name) onSelected;
  final String? excludingId;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final account = await showModalBottomSheet<Account>(
          context: context,
          isScrollControlled: true,
          builder: (context) => BlocProvider(
            create: (context) =>
                _started(getIt<AccountsListCubit>(), (c) => c.start()),
            child: AccountPickerSheetBody(excludingId: excludingId),
          ),
        );
        if (account != null) {
          onSelected(account.id, account.name);
        }
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(selectedName ?? label),
      ),
    );
  }
}

class AccountPickerSheetBody extends StatelessWidget {
  const AccountPickerSheetBody({this.excludingId, super.key});

  final String? excludingId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountsListCubit, AccountsListState>(
      builder: (context, state) {
        final entries = [
          for (final entry in state.accounts)
            if (entry.account.id != excludingId) entry,
        ];
        return SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final entry in entries)
                ListTile(
                  title: Text(entry.account.name),
                  onTap: () => Navigator.of(context).pop(entry.account),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// A minimal "pick from a bottom sheet" category field, reusing the
/// categories feature's own `CategoriesListCubit`.
class CategoryPickerField extends StatelessWidget {
  const CategoryPickerField({
    required this.kind,
    required this.selectedId,
    required this.selectedName,
    required this.onSelected,
    super.key,
  });

  final CategoryKind kind;
  final String? selectedId;

  /// Rendered instead of the placeholder label once a selection exists —
  /// without this the button never shows which category the user picked.
  final String? selectedName;

  final void Function(String? id, CategoryKind? kind, String? name) onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton(
      onPressed: () async {
        final picked = await showModalBottomSheet<Category?>(
          context: context,
          isScrollControlled: true,
          builder: (context) => BlocProvider(
            create: (context) => _started(
              getIt<CategoriesListCubit>(),
              (c) => c.start(kind: kind),
            ),
            child: const CategoryPickerSheetBody(),
          ),
        );
        onSelected(picked?.id, picked?.kind, picked?.name);
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(selectedName ??
            (selectedId == null
                ? l10n.transactionFormCategoryNone
                : l10n.transactionFormCategoryLabel)),
      ),
    );
  }
}

class CategoryPickerSheetBody extends StatelessWidget {
  const CategoryPickerSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<CategoriesListCubit, CategoriesListState>(
      builder: (context, state) {
        return SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ListTile(
                title: Text(l10n.transactionFormCategoryNone),
                onTap: () => Navigator.of(context).pop(),
              ),
              for (final node in state.nodes) ..._nodeTiles(context, node),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _nodeTiles(BuildContext context, CategoryNode node) => [
        ListTile(
          title: Text(node.root.name),
          onTap: () => Navigator.of(context).pop(node.root),
        ),
        for (final subcategory in node.subcategories)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: ListTile(
              title: Text(subcategory.name),
              onTap: () => Navigator.of(context).pop(subcategory),
            ),
          ),
      ];
}

/// Kicks off a cubit's initial load without awaiting it (it emits its loading
/// state synchronously and the sheet renders it), and hands it straight to
/// `BlocProvider` — same pattern as `createAppRouter`'s own helper.
T _started<T>(T cubit, Future<void> Function(T cubit) start) {
  unawaited(start(cubit));
  return cubit;
}
