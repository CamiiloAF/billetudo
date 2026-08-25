import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../home/domain/entities/quick_access_item.dart';
import '../cubit/app_settings_cubit.dart';
import '../cubit/app_settings_state.dart';

/// "Orden del acceso rápido" (Ajustes ▸ Preferencias): a standard reorderable
/// list — same `Page Header` + surface-card row style as the rest of Ajustes
/// — to change the order Home's `QuickAccessRow` renders its three chips in.
///
/// Persists on every drop via [AppSettingsCubit.setQuickAccessOrder]: the
/// list optimistically reorders itself locally so the drag feels immediate,
/// then the settings stream re-emits the stored value and confirms it —
/// same pattern as every other toggle in Ajustes.
class QuickAccessOrderPage extends StatefulWidget {
  const QuickAccessOrderPage({super.key});

  @override
  State<QuickAccessOrderPage> createState() => _QuickAccessOrderPageState();
}

class _QuickAccessOrderPageState extends State<QuickAccessOrderPage> {
  List<QuickAccessItem>? _localOrder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: l10n.settingsQuickAccessOrderTitle),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.settingsQuickAccessOrderHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                ),
              ),
            ),
            Expanded(
              child: BlocConsumer<AppSettingsCubit, AppSettingsState>(
                listenWhen: (previous, current) =>
                    previous.quickAccessOrder != current.quickAccessOrder,
                listener: (context, state) =>
                    setState(() => _localOrder = null),
                builder: (context, state) {
                  final order = _localOrder ?? state.quickAccessOrder;
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: order.length,
                    onReorder: (oldIndex, newIndex) =>
                        _onReorder(context, order, oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final item = order[index];
                      return Padding(
                        key: ValueKey(item),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QuickAccessOrderRow(item: item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onReorder(
    BuildContext context,
    List<QuickAccessItem> order,
    int oldIndex,
    int newIndex,
  ) {
    final updated = List<QuickAccessItem>.of(order);
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = updated.removeAt(oldIndex);
    updated.insert(adjustedNewIndex, item);
    setState(() => _localOrder = updated);
    unawaited(context.read<AppSettingsCubit>().setQuickAccessOrder(updated));
  }
}

/// One draggable row: icon + label + drag handle, same surface-card style as
/// `SettingsField` but without a chevron (this row does not navigate).
class QuickAccessOrderRow extends StatelessWidget {
  const QuickAccessOrderRow({required this.item, super.key});

  final QuickAccessItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(_iconFor(item), size: 20, color: colors.primaryOnSoft),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _labelFor(l10n, item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(LucideIcons.gripVertical, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(QuickAccessItem item) => switch (item) {
        QuickAccessItem.scheduledPayments => LucideIcons.calendarClock,
        QuickAccessItem.debts => LucideIcons.handCoins,
        QuickAccessItem.reports => LucideIcons.chartColumn,
      };

  String _labelFor(AppLocalizations l10n, QuickAccessItem item) =>
      switch (item) {
        QuickAccessItem.scheduledPayments =>
          l10n.homeQuickAccessScheduledPayments,
        QuickAccessItem.debts => l10n.moreDebts,
        QuickAccessItem.reports => l10n.moreReports,
      };
}
