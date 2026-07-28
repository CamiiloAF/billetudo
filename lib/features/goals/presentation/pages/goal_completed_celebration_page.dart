import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../utils/goal_format.dart';
import '../widgets/goal_progress_ring.dart';

/// HU-07's 100% full-screen celebration (`HH46w`): a festive `$mint-soft`
/// background, a trophy medallion, permanent-achievement copy, and two
/// forward-looking CTAs — "Crear la próxima meta" (primary) and "Archivar
/// meta" (secondary). No rótulo, no repeat of the arc-with-percent (the ring
/// here is drawn already full, `$income-text`).
class GoalCompletedCelebrationPage extends StatelessWidget {
  const GoalCompletedCelebrationPage({
    required this.goalName,
    required this.savedMinor,
    required this.currency,
    required this.onCreateNext,
    required this.onArchive,
    super.key,
  });

  final String goalName;
  final int savedMinor;
  final String currency;
  final VoidCallback onCreateNext;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.mintSoft,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              GoalProgressRing(
                percent: 100,
                size: 168,
                strokeWidth: 12,
                completed: true,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.trophy, size: 40, color: colors.incomeText),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.goalCompletedBadge,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.incomeText,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.goalCompletedTitle(goalName),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.goalCompletedMessage(
                  GoalFormat.amount(savedMinor, currency),
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCreateNext,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(l10n.goalCompletedCreateNext),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onArchive,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: const Icon(LucideIcons.archive, size: 18),
                  label: Text(l10n.goalCompletedArchive),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
