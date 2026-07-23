import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/date_picker_sheet.dart';
import '../../../../accounts/domain/entities/account.dart';
import '../../../../accounts/presentation/cubit/accounts_list_cubit.dart';
import '../../../../transactions/presentation/pages/transaction_form_page.dart'
    show AccountPickerSheetBody;
import '../../../domain/entities/pending_scheduled_occurrence.dart';
import '../../../domain/entities/scheduled_payment.dart';
import '../../cubit/confirmation_sheet_cubit.dart';
import '../../cubit/confirmation_sheet_state.dart';
import '../../cubit/guided_review_cubit.dart';
import '../../cubit/guided_review_state.dart';
import '../../utils/scheduled_payment_format.dart';
import '../scheduled_category_icon_wrap.dart';
import '../scheduled_payment_editable_amount_field.dart';
import 'confirmation_sheet_field_row.dart';
import 'scheduled_scope_note.dart';
import 'snooze_sheet.dart';

/// What the mandatory confirmation sheet did (criterion 7), so the caller
/// (the "Por confirmar" list) can offer "Deshacer" for a skip/snooze.
enum ConfirmationSheetResult { confirmed, skipped, snoozed, cancelled }

/// HU-03's mandatory confirmation sheet: the only path that applies a pending
/// occurrence to the balance — there is no one-tap shortcut, not even from
/// the guided review (criterion 7).
class ConfirmationSheet extends StatelessWidget {
  const ConfirmationSheet({
    required this.source,
    this.allPending = const [],
    super.key,
  });

  final PendingScheduledOccurrence source;

  /// The full "por confirmar" list, when the caller has it — feeds the
  /// "Acumuladas" strip (how many other occurrences of this same template are
  /// still unconfirmed). Callers that only know about this one occurrence
  /// (the detail screen's lone pending badge) leave it empty, and the strip
  /// simply does not show.
  final List<PendingScheduledOccurrence> allPending;

  static Future<ConfirmationSheetResult?> show(
    BuildContext context, {
    required PendingScheduledOccurrence source,
    List<PendingScheduledOccurrence> allPending = const [],
  }) =>
      // Dismissible and draggable like every other sheet in the app: tapping
      // the scrim or dragging the handle down closes it. Dismissing is not a
      // shortcut past the mandatory confirmation (criterion 7) — it simply does
      // nothing (the occurrence stays awaiting); only the "Confirmar" button
      // applies it. The body wraps its content in `BottomSheetBase`, so the
      // chrome (handle, radius, scrim) matches the standard sheets.
      showModalBottomSheet<ConfirmationSheetResult>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        builder: (context) =>
            ConfirmationSheet(source: source, allPending: allPending),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<ConfirmationSheetCubit>()..load(source, allPending: allPending),
      child: const ConfirmationSheetBody(),
    );
  }
}

class ConfirmationSheetBody extends StatelessWidget {
  const ConfirmationSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConfirmationSheetCubit, ConfirmationSheetState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case ConfirmationSheetStatus.confirmed:
            Navigator.of(context).pop(ConfirmationSheetResult.confirmed);
          case ConfirmationSheetStatus.skipped:
            Navigator.of(context).pop(ConfirmationSheetResult.skipped);
          case ConfirmationSheetStatus.snoozed:
            Navigator.of(context).pop(ConfirmationSheetResult.snoozed);
          default:
            break;
        }
      },
      builder: (context, state) {
        if (!state.isReady) {
          return const BottomSheetBase(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final cubit = context.read<ConfirmationSheetCubit>();
        final source = state.source!;
        return BottomSheetBase(
          child: ConfirmationSheetFields(
            scheduledPaymentId: state.scheduledPaymentId,
            type: state.type,
            currency: state.currency,
            note: state.note,
            categoryName: state.categoryName,
            categoryIcon: source.categoryIcon,
            categoryColor: source.categoryColor,
            frequency: source.scheduledPayment.frequency,
            transferAccountName: state.transferAccountName,
            isTransfer: state.isTransfer,
            date: state.date!,
            accountId: state.accountId,
            accountName: state.accountName,
            amountMinor: state.amountMinor!,
            templateAmountMinor: source.scheduledPayment.amountMinor,
            isSaving: state.isSaving,
            pendingCountForTemplate: state.pendingCountForTemplate,
            oldestPendingDate: source.occurrence.effectiveDate,
            minDate: state.minDate,
            onDateChanged: cubit.dateChanged,
            onAccountSelected: cubit.accountSelected,
            onAmountChanged: cubit.amountChanged,
            onConfirm: cubit.confirm,
            onSkip: cubit.skip,
            onSnooze: () async {
              final result = await SnoozeSheet.show(
                context,
                scheduledPaymentId: state.scheduledPaymentId,
                occurrenceDate: source.occurrence.occurrenceDate,
                templateName: ScheduledPaymentFormat.templateName(
                  note: state.note,
                  isTransfer: state.isTransfer,
                  accountName: state.accountName ?? '',
                  transferAccountName: state.transferAccountName,
                  fallback:
                      AppLocalizations.of(context).scheduledPaymentUntitled,
                ),
                isTransfer: state.isTransfer,
                categoryIcon: source.categoryIcon,
                categoryColor: source.categoryColor,
              );
              if (result != null && context.mounted) {
                Navigator.of(context).pop(ConfirmationSheetResult.snoozed);
              }
            },
            onEdit: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop(ConfirmationSheetResult.cancelled);
              unawaited(
                router.push(
                  AppRoutes.editScheduledPayment(state.scheduledPaymentId),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// "Revisar todas" (HU-03): the same mandatory verification, stepped through
/// one pending occurrence at a time — never an "apply-all" shortcut.
class GuidedReviewSheet extends StatelessWidget {
  const GuidedReviewSheet({required this.pending, super.key});

  final List<PendingScheduledOccurrence> pending;

  static Future<void> show(
    BuildContext context, {
    required List<PendingScheduledOccurrence> pending,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => GuidedReviewSheet(pending: pending),
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GuidedReviewCubit>()..start(pending),
      child: const GuidedReviewSheetBody(),
    );
  }
}

class GuidedReviewSheetBody extends StatelessWidget {
  const GuidedReviewSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<GuidedReviewCubit, GuidedReviewState>(
      listenWhen: (previous, current) =>
          previous.isFinished != current.isFinished,
      listener: (context, state) {
        if (state.isFinished) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final current = state.current;
        if (!state.isReady || current == null) {
          return const BottomSheetBase(
            child: SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final cubit = context.read<GuidedReviewCubit>();
        return BottomSheetBase(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.scheduledGuidedReviewPosition(
                        state.position,
                        state.total,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.scheduledGuidedReviewExit),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GuidedReviewProgressBar(
                position: state.position,
                total: state.total,
              ),
              const SizedBox(height: 12),
              ConfirmationSheetFields(
                scheduledPaymentId: current.scheduledPayment.id,
                type: current.scheduledPayment.type,
                currency: current.scheduledPayment.currency,
                note: current.scheduledPayment.note,
                categoryName: current.categoryName,
                categoryIcon: current.categoryIcon,
                categoryColor: current.categoryColor,
                frequency: current.scheduledPayment.frequency,
                transferAccountName: current.transferAccountName,
                isTransfer: current.scheduledPayment.isTransfer,
                date: state.date!,
                accountId: state.accountId,
                accountName: state.accountName,
                amountMinor: state.amountMinor!,
                templateAmountMinor: current.scheduledPayment.amountMinor,
                isSaving: state.isSaving,
                pendingCountForTemplate: state.pendingCountForTemplate,
                oldestPendingDate: current.occurrence.effectiveDate,
                minDate: state.minDate,
                isGuided: true,
                onDateChanged: cubit.dateChanged,
                onAccountSelected: cubit.accountSelected,
                onAmountChanged: cubit.amountChanged,
                onConfirm: cubit.confirmCurrent,
                onSkip: cubit.skipCurrent,
                onSnooze: () async {
                  final result = await SnoozeSheet.show(
                    context,
                    scheduledPaymentId: current.scheduledPayment.id,
                    occurrenceDate: current.occurrence.occurrenceDate,
                    templateName: ScheduledPaymentFormat.templateName(
                      note: current.scheduledPayment.note,
                      isTransfer: current.scheduledPayment.isTransfer,
                      accountName: current.accountName,
                      transferAccountName: current.transferAccountName,
                      fallback:
                          AppLocalizations.of(context).scheduledPaymentUntitled,
                    ),
                    isTransfer: current.scheduledPayment.isTransfer,
                    categoryIcon: current.categoryIcon,
                    categoryColor: current.categoryColor,
                  );
                  if (result != null) {
                    await cubit.skipCurrent();
                  }
                },
                // Guided review never offers the "editar plantilla" shortcut
                // (see `ConfirmationSheetHead.onEdit`): tapping it would
                // navigate out of the flow and abort the batch review.
                onEdit: null,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The segmented progress bar of "Revisar todas" (item 3): one neutral
/// segment per occurrence in the batch, the current one painted `primary`.
class GuidedReviewProgressBar extends StatelessWidget {
  const GuidedReviewProgressBar({
    required this.position,
    required this.total,
    super.key,
  });

  /// 1-based.
  final int position;
  final int total;

  static const double _height = 4;
  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (total <= 0) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: i < position ? colors.primary : colors.muted,
                borderRadius: BorderRadius.circular(_height / 2),
              ),
              child: const SizedBox(height: _height),
            ),
          ),
        ],
      ],
    );
  }
}

/// The "Sheet Head" (item 2): the category icon-wrap, the template's display
/// name, a "categoría · frecuencia" subtitle and a pencil shortcut to edit
/// the template — replaces the old read-only "Categoría"/"Nota" rows, which
/// are now represented here instead of repeated further down.
class ConfirmationSheetHead extends StatelessWidget {
  const ConfirmationSheetHead({
    required this.isTransfer,
    this.isIncome = false,
    required this.accountName,
    required this.frequency,
    required this.onEdit,
    this.note,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.transferAccountName,
    super.key,
  });

  final bool isTransfer;

  /// `income` templates tint the icon tile `income-soft` instead of wearing
  /// the category's own colour (`EJAvD`): the head is the first place that
  /// says "this one adds money".
  final bool isIncome;
  final String accountName;
  final String? transferAccountName;

  /// The user-written name of the template, when there is one: it is the
  /// head's `Name`, so the category is left to the `Sub` instead of being
  /// printed twice.
  final String? note;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final ScheduledPaymentFrequency frequency;

  /// `null` while in guided review (`isGuided` on [ConfirmationSheetFields]):
  /// the pencil shortcut navigates out of the guided flow and would abort it
  /// if tapped by accident, so it is hidden there entirely instead of just
  /// disabled.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final title = ScheduledPaymentFormat.templateName(
      note: note,
      isTransfer: isTransfer,
      accountName: accountName,
      transferAccountName: transferAccountName,
      fallback: l10n.scheduledPaymentUntitled,
    );
    final subtitleParts = [
      if (categoryName != null && categoryName!.isNotEmpty) categoryName!,
      ScheduledPaymentFormat.frequencyLabel(l10n, frequency),
    ];

    return Row(
      children: [
        ScheduledCategoryIconWrap(
          isTransfer: isTransfer,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
          cornerRadius: 14,
          // `$income-soft` has no `AppColors` token yet; `mintSoft` is the
          // theme's soft green counterpart in both themes, paired here with
          // `incomeText` so the glyph keeps AA contrast on it.
          background: isIncome ? colors.mintSoft : null,
          foreground: isIncome ? colors.incomeText : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitleParts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            tooltip: l10n.scheduledConfirmationSheetEditTooltip,
            icon: const Icon(LucideIcons.pencil),
            color: colors.textSecondary,
          ),
      ],
    );
  }
}

/// The "Acumuladas" strip (item 2): shown only when 2+ occurrences of the
/// same template are still unconfirmed, so the backlog is visible even
/// though — same as everywhere else in this feature — only one is resolved
/// at a time (criterion 11).
class ScheduledAccumulatedStrip extends StatelessWidget {
  const ScheduledAccumulatedStrip({
    required this.count,
    required this.templateTitle,
    required this.oldestDate,
    super.key,
  });

  final int count;
  final String templateTitle;
  final DateTime oldestDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.layers, size: 16, color: colors.primaryOnSoftStrong),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.scheduledConfirmationSheetAccumulatedTitle(
                    count,
                    templateTitle,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.primaryOnSoftStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.scheduledConfirmationSheetAccumulatedSub(
                    DateFormat.yMMMd(Localizations.localeOf(context).toString())
                        .format(oldestDate),
                    count - 1,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The shared fields/actions of the confirmation sheet, reused by both the
/// standalone [ConfirmationSheet] and [GuidedReviewSheet] — same layout,
/// different cubit behind the callbacks.
///
/// `categoryId`/`type`/`currency` render read-only (criterion 7) — via the
/// Sheet Head, not a row — while `date`/`accountId`/`amountMinor` are
/// editable, and editing them here never touches the template (criterion 8).
class ConfirmationSheetFields extends StatelessWidget {
  const ConfirmationSheetFields({
    required this.scheduledPaymentId,
    required this.type,
    required this.currency,
    required this.isTransfer,
    required this.frequency,
    required this.date,
    required this.accountId,
    required this.accountName,
    required this.amountMinor,
    required this.templateAmountMinor,
    required this.isSaving,
    required this.pendingCountForTemplate,
    required this.oldestPendingDate,
    this.minDate,
    required this.onDateChanged,
    required this.onAccountSelected,
    required this.onAmountChanged,
    required this.onConfirm,
    required this.onSkip,
    required this.onSnooze,
    required this.onEdit,
    this.note,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.transferAccountName,
    this.isGuided = false,
    super.key,
  });

  final String scheduledPaymentId;
  final ScheduledPaymentType type;
  final String currency;
  final bool isTransfer;

  /// The template's user-written name (its `note`), used as the head's title.
  final String? note;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? transferAccountName;
  final ScheduledPaymentFrequency frequency;

  final DateTime date;
  final String? accountId;
  final String? accountName;
  final int amountMinor;

  /// The amount the *template* holds, which the Scope Note quotes as what the
  /// next occurrence will propose — unaffected by edits made here.
  final int templateAmountMinor;

  final bool isSaving;

  /// True while stepped through "Revisar todas": swaps the primary button's
  /// label/icon to "Confirmar y siguiente" (item 3).
  final bool isGuided;

  /// How many pending occurrences share this template — feeds the
  /// "Acumuladas" strip when 2+.
  final int pendingCountForTemplate;
  final DateTime oldestPendingDate;

  /// The floor the date picker enforces (`disabledBefore`): the owning debt's
  /// `startDate` when this is a cuota, `null` (no floor) for an ordinary
  /// scheduled payment. A cuota must never be recorded before its debt began.
  final DateTime? minDate;

  final ValueChanged<DateTime> onDateChanged;
  final void Function(String id, String name) onAccountSelected;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onConfirm;
  final VoidCallback onSkip;
  final VoidCallback onSnooze;

  /// `null` when [isGuided] is true — see [ConfirmationSheetHead.onEdit].
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final resolvedAccountName = accountName ?? transferAccountName ?? '';
    final templateName = ScheduledPaymentFormat.templateName(
      note: note,
      isTransfer: isTransfer,
      accountName: resolvedAccountName,
      transferAccountName: transferAccountName,
      fallback: l10n.scheduledPaymentUntitled,
    );
    final divider = Divider(height: 1, thickness: 1, color: colors.border);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConfirmationSheetHead(
          isTransfer: isTransfer,
          isIncome: type == ScheduledPaymentType.income,
          accountName: resolvedAccountName,
          transferAccountName: transferAccountName,
          note: note,
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
          frequency: frequency,
          onEdit: isGuided ? null : onEdit,
        ),
        if (pendingCountForTemplate >= 2) ...[
          const SizedBox(height: 12),
          ScheduledAccumulatedStrip(
            count: pendingCountForTemplate,
            templateTitle: templateName,
            oldestDate: oldestPendingDate,
          ),
        ],
        const SizedBox(height: 8),
        ConfirmationSheetFieldRow(
          label: l10n.transactionFormDateLabel,
          value: DateFormat.yMMMd(Localizations.localeOf(context).toString())
              .format(date),
          onTap: () async {
            // A payment can only be recorded up to today — never in the future.
            // Confirming ahead of schedule records it now, not on its future
            // due date.
            final picked = await DatePickerSheet.show(
              context,
              initialDate: date,
              // A cuota can never be recorded before its debt started: the
              // owning debt's `startDate` is the floor. Non-cuota payments pass
              // `null` here and keep no lower bound.
              disabledBefore:
                  minDate == null ? null : DateUtils.dateOnly(minDate!),
              disabledAfter: DateUtils.dateOnly(DateTime.now()),
            );
            if (picked != null) {
              onDateChanged(picked);
            }
          },
        ),
        divider,
        ConfirmationSheetFieldRow(
          label: isTransfer
              ? l10n.scheduledConfirmationSheetSourceAccountLabel
              : l10n.transactionFormAccountLabel,
          value: accountName ?? '',
          onTap: () => unawaited(_pickAccount(context)),
        ),
        // A transfer's destination account (HU-04) is shown but not
        // selectable here: the confirmation sheet only ever edits
        // `date`/`accountId`/`amountMinor` (HU-03), so it carries no chevron.
        if (isTransfer) ...[
          divider,
          ConfirmationSheetFieldRow(
            label: l10n.scheduledConfirmationSheetTargetAccountLabel,
            value: transferAccountName ?? '',
          ),
        ],
        const SizedBox(height: 12),
        // Omitted for a `once` template: there is no future occurrence whose
        // scope needs clarifying (page spec, "Scope Note").
        if (frequency != ScheduledPaymentFrequency.once)
          ScheduledScopeNote(
            templateAmountMinor: templateAmountMinor,
            currency: currency,
          ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ScheduledPaymentEditableAmountField(
              amountMinor: amountMinor,
              currency: currency,
              label: isTransfer
                  ? l10n.scheduledConfirmationSheetTransferAmountLabel
                  : l10n.scheduledConfirmationSheetAmountLabel,
              valueColor: ScheduledPaymentFormat.amountColor(colors, type),
              // Prominent single-amount display: only income carries a '+'
              // (same reasoning as the detail hero). The list rows carry the
              // expense '-'.
              amountPrefix: type == ScheduledPaymentType.income ? '+' : '',
              // The sheet carries its own Confirmar button below, so the keypad
              // omits its Confirm key and the `=` spans the full width.
              confirmEnabled: false,
              onChanged: onAmountChanged,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : onSnooze,
                icon: const Icon(LucideIcons.alarmClock, size: 16),
                label: Text(l10n.scheduledConfirmationSheetSnooze),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : onSkip,
                icon: const Icon(LucideIcons.circleSlash, size: 16),
                label: Text(l10n.scheduledConfirmationSheetSkip),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isSaving ? null : onConfirm,
            icon: Icon(isGuided ? LucideIcons.arrowRight : LucideIcons.check,
                size: 18),
            label: Text(
              isGuided
                  ? l10n.scheduledGuidedReviewConfirmNext
                  : l10n.scheduledConfirmationSheetConfirm,
            ),
          ),
        ),
      ],
    );
  }

  /// Opens the shared account picker sheet (the same `AccountPickerSheetBody`
  /// Transacciones uses) from the boxless "Cuenta" row: this sheet needs the
  /// picker's behaviour, not the `Form Field` chrome of `AccountPickerField`.
  Future<void> _pickAccount(BuildContext context) async {
    final account = await BottomSheetBase.show<Account>(
      context,
      builder: (context) => BlocProvider(
        create: (context) {
          final cubit = getIt<AccountsListCubit>();
          unawaited(cubit.start());
          return cubit;
        },
        child: AccountPickerSheetBody(selectedId: accountId),
      ),
    );
    if (account != null) {
      onAccountSelected(account.id, account.name);
    }
  }
}
