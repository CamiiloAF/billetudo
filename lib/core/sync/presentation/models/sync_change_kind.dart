import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../l10n/gen/app_localizations.dart';

/// What a held-back write is *about*, in the user's own vocabulary.
///
/// The mapping from a remote table name to one of these lives here, in
/// `presentation`, because it exists to translate: HU-08 forbids showing table
/// names, error codes or ISO timestamps anywhere outside the technical log.
/// The user reads "Movimiento · Café con Ana", never `transactions`.
enum SyncChangeKind {
  transaction,
  account,
  budget,
  goal,
  goalContribution,
  debt,
  debtEntry,
  scheduledPayment,
  category,
  tag,
  settings,

  /// A table we have no copy for. Renders as a neutral "Cambio" instead of
  /// leaking the table name — an unmapped row must degrade, never expose.
  other;

  static SyncChangeKind fromTableName(String tableName) => switch (tableName) {
        'transactions' => SyncChangeKind.transaction,
        'accounts' => SyncChangeKind.account,
        'budgets' ||
        'budget_accounts' ||
        'budget_categories' ||
        'budget_period_overrides' =>
          SyncChangeKind.budget,
        'goals' => SyncChangeKind.goal,
        'goal_contributions' => SyncChangeKind.goalContribution,
        'debts' => SyncChangeKind.debt,
        'debt_entries' => SyncChangeKind.debtEntry,
        'scheduled_payments' ||
        'scheduled_payment_tags' ||
        'scheduled_payment_occurrences' =>
          SyncChangeKind.scheduledPayment,
        'categories' => SyncChangeKind.category,
        'tags' || 'transaction_tags' => SyncChangeKind.tag,
        'app_settings' => SyncChangeKind.settings,
        _ => SyncChangeKind.other,
      };

  /// The glyph the design assigns to each kind in `VtiBc`'s instances.
  IconData get icon => switch (this) {
        SyncChangeKind.transaction => LucideIcons.receipt,
        SyncChangeKind.account => LucideIcons.wallet,
        SyncChangeKind.budget => LucideIcons.chartPie,
        SyncChangeKind.goal ||
        SyncChangeKind.goalContribution =>
          LucideIcons.target,
        SyncChangeKind.debt ||
        SyncChangeKind.debtEntry =>
          LucideIcons.handCoins,
        SyncChangeKind.scheduledPayment => LucideIcons.repeat,
        SyncChangeKind.category || SyncChangeKind.tag => LucideIcons.tags,
        SyncChangeKind.settings => LucideIcons.settings,
        SyncChangeKind.other => LucideIcons.cloudUpload,
      };

  String label(AppLocalizations l10n) => switch (this) {
        SyncChangeKind.transaction => l10n.syncEntityTransaction,
        SyncChangeKind.account => l10n.syncEntityAccount,
        SyncChangeKind.budget => l10n.syncEntityBudget,
        SyncChangeKind.goal => l10n.syncEntityGoal,
        SyncChangeKind.goalContribution => l10n.syncEntityGoalContribution,
        SyncChangeKind.debt => l10n.syncEntityDebt,
        SyncChangeKind.debtEntry => l10n.syncEntityDebtEntry,
        SyncChangeKind.scheduledPayment => l10n.syncEntityScheduledPayment,
        SyncChangeKind.category => l10n.syncEntityCategory,
        SyncChangeKind.tag => l10n.syncEntityTag,
        SyncChangeKind.settings => l10n.syncEntitySettings,
        SyncChangeKind.other => l10n.syncEntityOther,
      };
}
