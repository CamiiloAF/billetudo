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
import '../../../../transactions/presentation/pages/transaction_form_page.dart'
    show AccountPickerField;
import '../../../domain/entities/pending_scheduled_occurrence.dart';
import '../../../domain/entities/scheduled_payment.dart';
import '../../cubit/confirmation_sheet_cubit.dart';
import '../../cubit/confirmation_sheet_state.dart';
import '../../cubit/guided_review_cubit.dart';
import '../../cubit/guided_review_state.dart';
import '../../utils/scheduled_payment_format.dart';
import '../scheduled_category_icon_wrap.dart';
import '../scheduled_payment_editable_amount_field.dart';
import '../scheduled_payment_read_only_row.dart';
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
      showModalBottomSheet<ConfirmationSheetResult>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
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
            isSaving: state.isSaving,
            pendingCountForTemplate: state.pendingCountForTemplate,
            oldestPendingDate: source.occurrence.effectiveDate,
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
                templateTitle: ScheduledPaymentFormat.templateTitle(
                  categoryName: state.categoryName,
                  isTransfer: state.isTransfer,
                  accountName: state.accountName ?? '',
                  transferAccountName: state.transferAccountName,
                ),
              );
              if (result != null && context.mounted) {
                Navigator.of(context).pop(ConfirmationSheetResult.snoozed);
              }
            },
            onEdit: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop(ConfirmationSheetResult.cancelled);
              router.push(AppRoutes.editScheduledPayment(state.scheduledPaymentId));
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
      listenWhen: (previous, current) => previous.isFinished != current.isFinished,
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
                    child: GuidedReviewProgressBar(
                      position: state.position,
                      total: state.total,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.scheduledGuidedReviewPosition(
                      state.position,
                      state.total,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.scheduledGuidedReviewExit),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConfirmationSheetFields(
                scheduledPaymentId: current.scheduledPayment.id,
                type: current.scheduledPayment.type,
                currency: current.scheduledPayment.currency,
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
                isSaving: state.isSaving,
                pendingCountForTemplate: state.pendingCountForTemplate,
                oldestPendingDate: current.occurrence.effectiveDate,
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
                    templateTitle: ScheduledPaymentFormat.templateTitle(
                      categoryName: current.categoryName,
                      isTransfer: current.scheduledPayment.isTransfer,
                      accountName: current.accountName,
                      transferAccountName: current.transferAccountName,
                    ),
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
    required this.accountName,
    required this.frequency,
    required this.onEdit,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.transferAccountName,
    super.key,
  });

  final bool isTransfer;
  final String accountName;
  final String? transferAccountName;
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
    final title = ScheduledPaymentFormat.templateTitle(
      categoryName: categoryName,
      isTransfer: isTransfer,
      accountName: accountName,
      transferAccountName: transferAccountName,
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
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitleParts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Text(
        l10n.scheduledConfirmationSheetAccumulated(
          count,
          templateTitle,
          DateFormat.yMMMd(Localizations.localeOf(context).toString())
              .format(oldestDate),
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.primaryOnSoftStrong,
          fontWeight: FontWeight.w600,
        ),
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
    required this.isSaving,
    required this.pendingCountForTemplate,
    required this.oldestPendingDate,
    required this.onDateChanged,
    required this.onAccountSelected,
    required this.onAmountChanged,
    required this.onConfirm,
    required this.onSkip,
    required this.onSnooze,
    required this.onEdit,
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
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? transferAccountName;
  final ScheduledPaymentFrequency frequency;

  final DateTime date;
  final String? accountId;
  final String? accountName;
  final int amountMinor;

  final bool isSaving;

  /// True while stepped through "Revisar todas": swaps the primary button's
  /// label/icon to "Confirmar y siguiente" (item 3).
  final bool isGuided;

  /// How many pending occurrences share this template — feeds the
  /// "Acumuladas" strip when 2+.
  final int pendingCountForTemplate;
  final DateTime oldestPendingDate;

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
    final theme = Theme.of(context);
    final resolvedAccountName = accountName ?? transferAccountName ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConfirmationSheetHead(
          isTransfer: isTransfer,
          accountName: resolvedAccountName,
          transferAccountName: transferAccountName,
          categoryName: categoryName,
          categoryIcon: categoryIcon,
          categoryColor: categoryColor,
          frequency: frequency,
          onEdit: isGuided ? null : onEdit,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.scheduledConfirmationSheetScopeNote,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final picked = await DatePickerSheet.show(context, initialDate: date);
            if (picked != null) {
              onDateChanged(picked);
            }
          },
          child: ScheduledPaymentReadOnlyRow(
            label: l10n.transactionFormDateLabel,
            value: DateFormat.yMMMd(Localizations.localeOf(context).toString())
                .format(date),
            editable: true,
          ),
        ),
        const SizedBox(height: 8),
        if (!isTransfer)
          AccountPickerField(
            label: l10n.transactionFormAccountLabel,
            selectedId: accountId,
            selectedName: accountName,
            onSelected: onAccountSelected,
          ),
        const SizedBox(height: 12),
        ScheduledPaymentEditableAmountField(
          amountMinor: amountMinor,
          currency: currency,
          onChanged: onAmountChanged,
        ),
        if (pendingCountForTemplate >= 2) ...[
          const SizedBox(height: 16),
          ScheduledAccumulatedStrip(
            count: pendingCountForTemplate,
            templateTitle: ScheduledPaymentFormat.templateTitle(
              categoryName: categoryName,
              isTransfer: isTransfer,
              accountName: resolvedAccountName,
              transferAccountName: transferAccountName,
            ),
            oldestDate: oldestPendingDate,
          ),
        ],
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
        FilledButton.icon(
          onPressed: isSaving ? null : onConfirm,
          icon: Icon(isGuided ? LucideIcons.arrowRight : LucideIcons.check, size: 18),
          label: Text(
            isGuided
                ? l10n.scheduledGuidedReviewConfirmNext
                : l10n.scheduledConfirmationSheetConfirm,
          ),
        ),
      ],
    );
  }
}
