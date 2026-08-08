import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/date_range_picker_sheet.dart';
import '../../../../core/widgets/neutral_button.dart';
import '../../../../core/widgets/toggle_field.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/widgets/sheets/account_filter_sheet.dart';
import '../../../transactions/presentation/widgets/sheets/category_filter_sheet.dart';
import '../../../transactions/presentation/widgets/sheets/tag_filter_sheet.dart';
import '../../../transactions/presentation/widgets/sheets/type_filter_sheet.dart';
import '../../domain/entities/import_entry_type.dart';
import '../cubit/export_cubit.dart';
import '../cubit/export_state.dart';
import 'export_filter_chip.dart';
import 'sheets/export_run_sheet.dart';

/// The scope-picking form of `ExportPage` (HU-01/HU-02): which data to
/// export, its "Filtros de transacciones" (only live when "Transacciones" is
/// on, `zFLrC`/`h6ZQQw`), then the export CTA.
class ExportForm extends StatelessWidget {
  const ExportForm({required this.state, super.key});

  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final cubit = context.read<ExportCubit>();
    final scope = state.scope;
    final range = scope.transactionFilter;
    final filtersEnabled = scope.includeTransactions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        ToggleField(
          icon: LucideIcons.receipt,
          label: l10n.importExportScopeTransactions,
          value: scope.includeTransactions,
          hint: l10n.importExportScopeTransactionsHint,
          onChanged: (value) => cubit.toggleIncludeTransactions(value: value),
        ),
        const SizedBox(height: 12),
        ToggleField(
          icon: LucideIcons.wallet,
          label: l10n.importExportScopeAccounts,
          value: scope.includeAccounts,
          hint: l10n.importExportScopeAccountsHint,
          onChanged: (value) => cubit.toggleIncludeAccounts(value: value),
        ),
        const SizedBox(height: 12),
        ToggleField(
          icon: LucideIcons.shapes,
          label: l10n.importExportScopeCategories,
          value: scope.includeCategories,
          hint: l10n.importExportScopeCategoriesHint,
          onChanged: (value) => cubit.toggleIncludeCategories(value: value),
        ),
        const SizedBox(height: 24),
        if (scope.bundlesIntoZip) ...[
          Text(
            l10n.importExportZipNotice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 20),
        ],
        Opacity(
          // MASTER.md: `~0.6` is the accepted opacity floor for an
          // explicitly non-interactive block — never lower, it stops being
          // legible (`design-system/billetudo/pages/import-export.md`).
          opacity: filtersEnabled ? 1 : 0.6,
          child: IgnorePointer(
            ignoring: !filtersEnabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.importExportFiltersTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.importExportFiltersSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                ),
                const SizedBox(height: 10),
                TextField(
                  enabled: filtersEnabled,
                  onChanged: cubit.setSearchText,
                  decoration: InputDecoration(
                    prefixIcon: Icon(LucideIcons.search,
                        size: 18, color: colors.textSecondary),
                    hintText: l10n.importExportFilterSearchPlaceholder,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ExportFilterChip(
                        leadingIcon: LucideIcons.wallet,
                        label: range.accountIds.isEmpty
                            ? l10n.importExportFilterAllAccounts
                            : l10n.transactionsFilterAccountsSelected(
                                range.accountIds.length),
                        active: range.accountIds.isNotEmpty,
                        enabled: filtersEnabled,
                        onTap: () async {
                          final selected = await AccountFilterSheet.show(
                            context,
                            initialSelected: range.accountIds,
                          );
                          if (selected != null) {
                            cubit.setAccountFilter(selected);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ExportFilterChip(
                        label: range.categoryIds.isEmpty
                            ? l10n.transactionsFilterCategories
                            : l10n.transactionsFilterCategoriesSelected(
                                range.categoryIds.length),
                        active: range.categoryIds.isNotEmpty,
                        enabled: filtersEnabled,
                        onTap: () async {
                          final selected = await CategoryFilterSheet.show(
                            context,
                            initialSelected: range.categoryIds,
                          );
                          if (selected != null) {
                            cubit.setCategoryFilter(selected);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ExportFilterChip(
                        label: range.types.isEmpty
                            ? l10n.transactionsFilterType
                            : l10n.transactionsFilterTypeSelected(
                                range.types.length),
                        active: range.types.isNotEmpty,
                        enabled: filtersEnabled,
                        onTap: () async {
                          final selected = await TypeFilterSheet.show(
                            context,
                            initialSelected:
                                range.types.map(_toTransactionType).toSet(),
                          );
                          if (selected != null) {
                            cubit.setTypeFilter(
                                selected.map(_toImportEntryType).toSet());
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ExportFilterChip(
                        label: range.tagIds.isEmpty
                            ? l10n.transactionsFilterTag
                            : l10n.transactionsFilterTagSelected(
                                range.tagIds.length),
                        active: range.tagIds.isNotEmpty,
                        enabled: filtersEnabled,
                        onTap: () async {
                          final selected = await TagFilterSheet.show(
                            context,
                            initialSelected: range.tagIds,
                          );
                          if (selected != null) {
                            cubit.setTagFilter(selected);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ToggleField(
                  icon: LucideIcons.history,
                  label: l10n.importExportAllHistory,
                  value: scope.allHistory,
                  hint: l10n.importExportAllHistoryHint,
                  enabled: filtersEnabled,
                  onChanged: (value) => cubit.toggleAllHistory(value: value),
                ),
                if (!scope.allHistory) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: !filtersEnabled
                        ? null
                        : () async {
                            final now = clock.now();
                            final applied = await DateRangePickerSheet.show(
                              context,
                              initialStart: range.startDate ??
                                  DateTime(now.year, now.month - 1, now.day),
                              initialEnd: range.endDate ?? now,
                            );
                            if (applied != null) {
                              cubit.updateDateRange(applied.start, applied.end);
                            }
                          },
                    icon: const Icon(LucideIcons.calendarRange, size: 18),
                    label: Text(
                      range.startDate == null || range.endDate == null
                          ? l10n.importExportPickDateRange
                          : '${DateFormat.yMd(l10n.localeName).format(range.startDate!)} '
                              '– ${DateFormat.yMd(l10n.localeName).format(range.endDate!)}',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        NeutralButton(
          label: l10n.importExportExportCta,
          icon: LucideIcons.share2,
          enabled: scope.selectionCount,
          onPressed: () => unawaited(
            ExportRunSheet.show(context,
                cubit: cubit, language: l10n.localeName),
          ),
        ),
      ],
    );
  }

  TransactionType _toTransactionType(ImportEntryType type) => switch (type) {
        ImportEntryType.income => TransactionType.income,
        ImportEntryType.expense => TransactionType.expense,
        ImportEntryType.transfer => TransactionType.transfer,
      };

  ImportEntryType _toImportEntryType(TransactionType type) => switch (type) {
        TransactionType.income => ImportEntryType.income,
        TransactionType.expense => ImportEntryType.expense,
        TransactionType.transfer => ImportEntryType.transfer,
      };
}
