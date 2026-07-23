import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../../../../../core/widgets/sheet_list_viewport.dart';
import '../../../domain/entities/budget_scheduled_item.dart';
import '../budget_scheduled_row.dart';

/// The "programado" list (HU-12): what composes `BudgetProgress.scheduledMinor`
/// for the currently selected period, opened from the detail hero's entry row.
/// Read-only — there is nothing to pick here, so unlike the picker sheets this
/// one has no confirm button, just a head and the list.
class BudgetScheduledSheet extends StatelessWidget {
  const BudgetScheduledSheet({
    required this.items,
    required this.totalMinor,
    required this.currency,
    required this.onOpenScheduledPayment,
    required this.onSeeAllScheduled,
    super.key,
  });

  /// Soonest first (already sorted by the domain, see
  /// `BudgetProgressCalculator.scheduledItemsIn`).
  final List<BudgetScheduledItem> items;

  /// `BudgetProgress.scheduledMinor` for the shown period.
  final int totalMinor;
  final String currency;

  /// Called with a row's `scheduledPaymentId` to open the template's detail.
  final ValueChanged<String> onOpenScheduledPayment;

  /// Opens the global Pagos Programados list (bugfix item 11). The footer pops
  /// this sheet before invoking it, so the caller only navigates.
  final VoidCallback onSeeAllScheduled;

  static Future<void> show(
    BuildContext context, {
    required List<BudgetScheduledItem> items,
    required int totalMinor,
    required String currency,
    required ValueChanged<String> onOpenScheduledPayment,
    required VoidCallback onSeeAllScheduled,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BudgetScheduledSheet(
          items: items,
          totalMinor: totalMinor,
          currency: currency,
          onOpenScheduledPayment: onOpenScheduledPayment,
          onSeeAllScheduled: onSeeAllScheduled,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();
    final isEmpty = items.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHead(
          title: l10n.budgetScheduledSheetTitle,
          // `Tg476`: the empty state names the fact itself, so the head
          // shows only the title here — no hint repeating that message.
          hint: isEmpty
              ? null
              : l10n.budgetScheduledSheetHint(
                  money.formatSymbol(totalMinor, currencyCode: currency),
                ),
        ),
        const SizedBox(height: 16),
        SheetListViewport(
          height: 320,
          child: isEmpty
              ? EmptyState(
                  icon: LucideIcons.calendarClock,
                  message: l10n.budgetScheduledSheetEmpty,
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) => BudgetScheduledRow(
                    item: items[index],
                    onTap: (id) {
                      Navigator.of(context).pop();
                      // Deferred to the next frame instead of calling it
                      // right here: firing the push in the same frame as
                      // this `pop()` makes both Navigator transitions
                      // compete, which drops frames and gives the
                      // destination page's initial "loading" state (the
                      // stream cubit always starts there) enough time to
                      // paint visibly before its query resolves. This still
                      // has to run — omitting it entirely reintroduces the
                      // original bug where the imperative sheet route
                      // swallowed the declarative push and the page got
                      // stuck loading.
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => onOpenScheduledPayment(id),
                      );
                    },
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Divider(height: 1, thickness: 1, color: context.colors.border),
        const SizedBox(height: 16),
        BudgetScheduledSeeAllFooter(
          onTap: () {
            Navigator.of(context).pop();
            // Deferred past this frame for the same reason as the row's push
            // above: firing navigation while the sheet route pops makes both
            // Navigator transitions compete and drop frames.
            WidgetsBinding.instance
                .addPostFrameCallback((_) => onSeeAllScheduled());
          },
        ),
      ],
    );
  }
}

/// The sheet's footer link (`V2xIK`): a calendar-clock + label + chevron row
/// that leaves for the global Pagos Programados list (bugfix item 11).
class BudgetScheduledSeeAllFooter extends StatelessWidget {
  const BudgetScheduledSeeAllFooter({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(LucideIcons.calendarClock,
                size: 18, color: colors.primaryOnSoftStrong),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.budgetScheduledSheetSeeAll,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryOnSoftStrong,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(LucideIcons.chevronRight,
                size: 18, color: colors.primaryOnSoftStrong),
          ],
        ),
      ),
    );
  }
}
