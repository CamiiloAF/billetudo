import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/date_picker_sheet.dart';
import '../../../../../core/widgets/note_autocomplete_field.dart';
import '../../../domain/entities/debt.dart';
import '../../../domain/entities/debt_entry.dart';
import '../../../domain/entities/debt_ledger_entry.dart';
import '../../cubit/debt_entry_edit_cubit.dart';
import '../../cubit/debt_entry_edit_state.dart';
import '../../utils/debt_format.dart';
import '../debt_amount_hero_field.dart';
import '../debt_form_field.dart';
import 'confirm_delete_debt_entry_sheet.dart';

/// The view/edit sheet for a solo-deuda ledger row (a cash-less abono,
/// desembolso, an interest accrual, or a manual adjustment) — opened directly
/// from `DebtLedgerRow`'s tap, replacing the old two-step
/// `DebtMovementDetailSheet` → `DebtEntryEditSheet` flow.
///
/// Renders one of two bodies depending on [DebtEntryEditState.editable]:
///  * editable (abono/desembolso/ajuste): the amount/date/note form, a
///    "Guardar cambios" CTA, and a "Eliminar movimiento" link.
///  * read-only (interest accrual, never hand-edited — `UpdateDebtEntry`
///    enforces this in domain): the same fields as plain info rows, plus a
///    single full-width "Eliminar" button.
/// Both variants can delete the entry outright (`DeleteDebtEntry` allows
/// every kind), confirmed first by `ConfirmDeleteDebtEntrySheet`.
class DebtEntryEditSheet extends StatelessWidget {
  const DebtEntryEditSheet({required this.debt, super.key});

  final Debt debt;

  /// Opens the sheet for [entry], which must belong to [debt]. [runningMinor]
  /// is the debt's balance right after this entry (`DebtDetailCubit`'s
  /// newest-first running balance, already resolved by the caller).
  static Future<void> show(
    BuildContext context, {
    required Debt debt,
    required DebtEntry entry,
    required int runningMinor,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BlocProvider(
          create: (context) => getIt<DebtEntryEditCubit>()
            ..start(entry, runningMinor: runningMinor),
          child: DebtEntryEditSheet(debt: debt),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebtEntryEditCubit, DebtEntryEditState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == DebtEntryEditStatus.saved) {
          BottomSheetBase.dismiss(context);
        }
      },
      builder: (context, state) => state.editable
          ? DebtEntryEditSheetBody(debt: debt, state: state)
          : DebtEntryReadOnlySheetBody(debt: debt, state: state),
    );
  }
}

/// One label/value row of the merged sheet ("Saldo después" in both
/// variants): label and value share a row, the value expanding to fill the
/// rest of the width — its own public widget (`avoid_widget_functions`).
class DebtEntryEditInlineRow extends StatelessWidget {
  const DebtEntryEditInlineRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// One label/value row inside [DebtEntryReadOnlySheetBody]'s info card
/// (Fecha/Nota): label stacked above the value, no input box or affordance
/// icon — the read-only variant never invites a tap. Its own public widget
/// (`avoid_widget_functions`), the full note wraps freely instead of the
/// 1-line ellipsis `DebtLedgerRow` uses.
class DebtEntryReadOnlyInfoRow extends StatelessWidget {
  const DebtEntryReadOnlyInfoRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Confirms and deletes the entry driving [cubit], shared by both sheet
/// bodies' delete affordance. `ConfirmDeleteDebtEntrySheet` opens on the same
/// [context] the entry-edit sheet is already on, stacking a second modal on
/// the same root navigator (`BottomSheetBase.show` always targets it).
Future<void> confirmAndDeleteDebtEntry(
  BuildContext context,
  DebtEntryEditCubit cubit,
) async {
  final confirmed = await ConfirmDeleteDebtEntrySheet.show(context);
  if ((confirmed ?? false) && context.mounted) {
    await cubit.delete();
  }
}

/// The editable body: an abono, desembolso, or manual adjustment. Structurally
/// a smaller sibling of `DebtPaymentSheet`: same héroe/fecha/nota shape, no
/// account/category fields (this entry never carries either), no kind toggle
/// (`kind` is fixed on an edit) — plus the read-only "Saldo después" row and
/// the "Eliminar movimiento" link the merged sheet adds.
class DebtEntryEditSheetBody extends StatelessWidget {
  const DebtEntryEditSheetBody({
    required this.debt,
    required this.state,
    super.key,
  });

  final Debt debt;
  final DebtEntryEditState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final cubit = context.read<DebtEntryEditCubit>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.debtEntryEditTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DebtFormat.context(l10n, debt.name, debt.direction),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                DebtAmountHeroField(
                  fieldKey: const ValueKey('debt-entry-edit-amount'),
                  label: DebtFormat.entryKindLabel(
                    l10n,
                    state.entry.kind,
                    debt.direction,
                  ),
                  currency: debt.currency,
                  initialAmountMinor: state.amountMinor,
                  onChanged: cubit.amountChanged,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DebtEntryEditInlineRow(
                  label: l10n.debtEntryEditBalanceLabel,
                  value: DebtFormat.amount(state.runningMinor, debt.currency),
                ),
                const SizedBox(height: 16),
                DebtFormField.selector(
                  label: l10n.debtEntryEditDateLabel,
                  icon: LucideIcons.calendar,
                  value: DebtFormat.relativeDate(context, l10n, state.date),
                  onTap: () => unawaited(
                    _pickDate(
                      context,
                      cubit,
                      state.date,
                      debt.effectiveStartDate,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                NoteAutocompleteField(
                  key: const ValueKey('debt-entry-edit-note'),
                  label: l10n.debtEntryEditNoteLabel,
                  icon: LucideIcons.pencil,
                  hint: l10n.debtPaymentNoteHint,
                  initialValue: state.note,
                  onChanged: cubit.noteChanged,
                ),
                if (state.failure != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.debtEntryEditError,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.expenseText),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton.icon(
            key: const ValueKey('debt-entry-edit-delete-link'),
            onPressed: state.canDelete
                ? () => unawaited(confirmAndDeleteDebtEntry(context, cubit))
                : null,
            style: TextButton.styleFrom(foregroundColor: colors.expenseText),
            icon: const Icon(LucideIcons.trash2, size: 16),
            label: Text(l10n.debtEntryEditDeleteLink),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('debt-entry-edit-submit'),
            onPressed: state.canSubmit ? cubit.submit : null,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(l10n.debtEntryEditCta),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    DebtEntryEditCubit cubit,
    DateTime current,
    DateTime floorDate,
  ) async {
    final picked = await DatePickerSheet.show(
      context,
      initialDate: current,
      // Same floor `DebtPaymentSheet` enforces: a solo-deuda entry can never
      // predate the debt's start date.
      disabledBefore: DateUtils.dateOnly(floorDate),
      disabledAfter: clock.now(),
    );
    if (picked != null) {
      cubit.dateChanged(picked);
    }
  }
}

/// The read-only body: an interest accrual. `UpdateDebtEntry` rejects hand-
/// editing it in domain, so this never offers a form — fecha/nota render as
/// plain info rows inside a card, and the only action is a full-width
/// "Eliminar".
class DebtEntryReadOnlySheetBody extends StatelessWidget {
  const DebtEntryReadOnlySheetBody({
    required this.debt,
    required this.state,
    super.key,
  });

  final Debt debt;
  final DebtEntryEditState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final cubit = context.read<DebtEntryEditCubit>();
    final entry = state.entry;
    final label = DebtFormat.entryKindLabel(l10n, entry.kind, debt.direction);
    final note = state.note;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                DebtFormat.ledgerIcon(DebtLedgerKind.interestAccrual),
                size: 20,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.debtLedgerTagEstimated,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                DebtFormat.amount(state.amountMinor, debt.currency),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colors.textPrimary,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DebtEntryEditInlineRow(
          label: l10n.debtEntryEditBalanceLabel,
          value: DebtFormat.amount(state.runningMinor, debt.currency),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DebtEntryReadOnlyInfoRow(
                label: l10n.debtEntryEditDateLabel,
                value: DebtFormat.dateLong(context, state.date),
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(height: 1, color: colors.border),
                const SizedBox(height: 16),
                DebtEntryReadOnlyInfoRow(
                  label: l10n.debtEntryEditNoteReadLabel,
                  value: note,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('debt-entry-edit-delete'),
            onPressed: state.canDelete
                ? () => unawaited(confirmAndDeleteDebtEntry(context, cubit))
                : null,
            style: FilledButton.styleFrom(backgroundColor: colors.expense),
            icon: const Icon(LucideIcons.trash2, size: 18),
            label: Text(l10n.commonDelete),
          ),
        ),
      ],
    );
  }
}
