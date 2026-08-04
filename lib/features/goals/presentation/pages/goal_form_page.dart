import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/date_picker_sheet.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../domain/entities/goal_draft.dart';
import '../cubit/goal_form_cubit.dart';
import '../cubit/goal_form_state.dart';
import '../utils/goal_format.dart';
import '../utils/goal_icon_appearance.dart';
import '../widgets/currency_pill.dart';
import '../widgets/goal_amount_hero_field.dart';
import '../widgets/goal_field_label.dart';
import '../widgets/goal_selector_box.dart';
import '../widgets/sheets/confirm_delete_goal_sheet.dart';
import '../widgets/sheets/goal_account_picker_sheet.dart';
import '../widgets/sheets/goal_currency_picker_sheet.dart';
import '../widgets/sheets/goal_icon_picker_sheet.dart';

/// Crear / editar meta (`PjBCt`/`M2f3R`, HU-01/HU-02/HU-08): ícono y nombre,
/// the objective amount as a compact dominant row, optional linked account
/// (locks the currency), optional fecha objetivo, and — on create only — an
/// optional, visually secondary "¿Ya tienes algo ahorrado?" starting figure.
/// Editing reveals "Eliminar meta" (papelera/undo, HU-10).
///
/// Pops with `true` when the goal was deleted.
class GoalFormPage extends StatelessWidget {
  const GoalFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GoalFormCubit, GoalFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case GoalFormStatus.saved:
            Navigator.of(context).pop();
          case GoalFormStatus.deleted:
            Navigator.of(context).pop(true);
          case GoalFormStatus.loading:
          case GoalFormStatus.ready:
          case GoalFormStatus.saving:
          case GoalFormStatus.failure:
            break;
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                GoalFormHeader(isEditing: state.isEditing),
                Expanded(
                  child: state.status == GoalFormStatus.loading
                      ? const Center(child: CircularProgressIndicator())
                      : GoalFormBody(state: state),
                ),
                GoalFormBottomBar(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GoalFormHeader extends StatelessWidget {
  const GoalFormHeader({required this.isEditing, super.key});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          // `PjBCt`'s `Dtm0X` Page Header always shows the back arrow, never
          // an "x" — crear/editar meta is a stacked screen, not a dismissible
          // sheet.
          PageHeaderCircleButton(
            icon: LucideIcons.arrowLeft,
            background: colors.muted,
            foreground: colors.textPrimary,
            tooltip: l10n.commonBack,
            onPressed: Navigator.of(context).pop,
          ),
          Expanded(
            child: Text(
              isEditing ? l10n.goalFormEditTitle : l10n.goalFormNewTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class GoalFormBody extends StatelessWidget {
  const GoalFormBody({required this.state, super.key});

  final GoalFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final cubit = context.read<GoalFormCubit>();
    final isCurrencyLocked = state.isCurrencyLocked;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      children: [
        GoalFieldLabel(l10n.goalFormIconAndNameLabel),
        const SizedBox(height: 6),
        GoalIconAndNameRow(state: state),
        const SizedBox(height: 16),
        GoalFieldLabel(l10n.goalFormTargetLabel),
        const SizedBox(height: 6),
        GoalAmountHeroField(
          key: ValueKey('target-${state.id ?? 'new'}'),
          fieldKey: const ValueKey('goal-amount-target'),
          label: l10n.goalFormTargetLabel,
          currency: state.currency,
          initialAmountMinor: state.targetMinor,
          onChanged: cubit.targetMinorChanged,
          errorText: state.failedField == GoalDraft.fieldTargetMinor
              ? l10n.goalFormErrorTargetZero
              : null,
          compact: true,
          compactTrailing: CurrencyPill(
            label: state.currency,
            locked: isCurrencyLocked,
            onTap: isCurrencyLocked
                ? null
                : () => unawaited(_pickCurrency(context, cubit, state.currency)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isCurrencyLocked
              ? l10n.goalFormCurrencyHintLocked(
                  _selectedAccountName(state) ?? '', state.currency)
              : l10n.goalFormCurrencyHintUnlocked,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: colors.textSecondary,
              ),
        ),
        const SizedBox(height: 14),
        GoalFieldLabel(l10n.goalFormAccountLabel),
        const SizedBox(height: 6),
        GoalSelectorBox(
          icon: LucideIcons.landmark,
          value: _selectedAccountName(state),
          hint: l10n.goalFormAccountHint,
          onTap: () => unawaited(_pickAccount(context, cubit, state)),
          onClear: state.accountId == null
              ? null
              : () => cubit.accountChanged(null),
        ),
        const SizedBox(height: 14),
        GoalFieldLabel(l10n.goalFormTargetDateLabel),
        const SizedBox(height: 6),
        GoalSelectorBox(
          icon: LucideIcons.calendar,
          value: state.targetDate == null
              ? null
              : GoalFormat.dateLong(context, state.targetDate!),
          hint: l10n.goalFormTargetDateHint,
          errorText: state.failedField == GoalDraft.fieldTargetDate
              ? l10n.goalFormErrorTargetDatePast
              : null,
          onTap: () => unawaited(_pickTargetDate(context, cubit, state.targetDate)),
          onClear: state.targetDate == null
              ? null
              : () => cubit.targetDateChanged(null),
        ),
        if (!state.isEditing) ...[
          const SizedBox(height: 14),
          GoalFieldLabel(l10n.goalFormInitialSavedLabel),
          const SizedBox(height: 6),
          GoalAmountHeroField(
            fieldKey: const ValueKey('goal-amount-initial'),
            label: l10n.goalFormInitialSavedLabel,
            currency: state.currency,
            initialAmountMinor: state.initialSavedMinor,
            onChanged: cubit.initialSavedMinorChanged,
            compact: true,
            compactLeadingIcon: LucideIcons.piggyBank,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.goalFormInitialSavedHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: colors.textSecondary,
                ),
          ),
        ],
        if (state.isEditing) ...[
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => unawaited(_confirmDelete(context, cubit)),
              style: TextButton.styleFrom(foregroundColor: colors.expense),
              icon: const Icon(LucideIcons.trash2, size: 18),
              label: Text(l10n.commonDelete),
            ),
          ),
        ],
      ],
    );
  }

  String? _selectedAccountName(GoalFormState state) {
    final accountId = state.accountId;
    if (accountId == null) {
      return null;
    }
    for (final entry in state.accounts) {
      if (entry.account.id == accountId) {
        return entry.account.name;
      }
    }
    return null;
  }

  Future<void> _pickCurrency(
    BuildContext context,
    GoalFormCubit cubit,
    String current,
  ) async {
    final picked = await GoalCurrencyPickerSheet.show(context, selected: current);
    if (picked != null) {
      cubit.currencyChanged(picked);
    }
  }

  Future<void> _pickAccount(
    BuildContext context,
    GoalFormCubit cubit,
    GoalFormState state,
  ) async {
    if (state.accounts.isEmpty) {
      return;
    }
    final picked = await GoalAccountPickerSheet.show(
      context,
      accounts: state.accounts,
      selectedId: state.accountId,
    );
    if (picked != null) {
      cubit.accountChanged(picked);
    }
  }

  Future<void> _pickTargetDate(
    BuildContext context,
    GoalFormCubit cubit,
    DateTime? current,
  ) async {
    final picked = await DatePickerSheet.show(
      context,
      initialDate: current,
      disabledBefore: DateTime.now(),
    );
    if (picked != null) {
      cubit.targetDateChanged(picked);
    }
  }

  Future<void> _confirmDelete(BuildContext context, GoalFormCubit cubit) async {
    final confirmed = await ConfirmDeleteGoalSheet.show(context);
    if ((confirmed ?? false) && context.mounted) {
      await cubit.delete();
    }
  }
}

/// The "Ícono y nombre" row (`PjBCt`'s `NxBR7`): a 52x52 tappable icon avatar
/// with a small pencil edit-badge, opening [GoalIconPickerSheet], next to the
/// name's own `Input Box`.
class GoalIconAndNameRow extends StatelessWidget {
  const GoalIconAndNameRow({required this.state, super.key});

  final GoalFormState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<GoalFormCubit>();
    final nameError = state.failedField == GoalDraft.fieldName
        ? l10n.goalFormNameRequired
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: l10n.goalIconSheetTitle,
          child: InkWell(
            onTap: () => unawaited(_pickIcon(context, cubit, state.icon)),
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      GoalIconAppearance.iconFor(state.icon),
                      size: 22,
                      color: colors.primaryOnSoft,
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border),
                      ),
                      child: Icon(
                        LucideIcons.pencil,
                        size: 10,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: nameError != null ? colors.expense : colors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: TextFormField(
                  key: ValueKey('name-${state.id ?? 'new'}'),
                  initialValue: state.name,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: GoalDraft.maxNameLength,
                  onChanged: cubit.nameChanged,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: l10n.goalFormNameHint,
                  ),
                ),
              ),
              if (nameError != null) ...[
                const SizedBox(height: 6),
                Text(
                  nameError,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.expense,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickIcon(
    BuildContext context,
    GoalFormCubit cubit,
    String? current,
  ) async {
    final picked = await GoalIconPickerSheet.show(context, selected: current);
    if (picked != null) {
      cubit.iconChanged(picked);
    }
  }
}

class GoalFormBottomBar extends StatelessWidget {
  const GoalFormBottomBar({required this.state, super.key});

  final GoalFormState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: FilledButton.icon(
        onPressed: state.isSaving ? null : context.read<GoalFormCubit>().submit,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        icon: const Icon(LucideIcons.check, size: 18),
        label: Text(state.isEditing ? l10n.goalFormSaveCta : l10n.goalFormCreateCta),
      ),
    );
  }
}
