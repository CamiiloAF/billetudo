import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/tutorials/domain/entities/tutorial_content.dart';
import '../../features/tutorials/presentation/utils/tutorial_icons.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'bottom_sheet_base.dart';

/// How a [TutorialSheet] closed.
enum TutorialSheetResult {
  /// The HU-01 primary CTA was tapped — the caller should navigate to the
  /// real create action next.
  cta,

  /// "Entendido" was tapped.
  gotIt,
}

/// The one shared minitutorial sheet (`docs/requirements/16-minitutoriales.md`)
/// every one of the 11 tutorials renders through — parameterized by
/// [TutorialContent], never a bespoke widget per feature.
///
/// Two shapes, driven by [TutorialContent.hasNavigationCta]:
/// - **HU-01** (screen tutorials): icon + title + 2-3 points + a primary CTA
///   that navigates to the real action, plus "Entendido" as a secondary
///   (outlined) button.
/// - **HU-02** (sub-flow tutorials): icon + title + 1-2 points + only
///   "Entendido", rendered as the primary (filled) button, with no icon on
///   it (criterion: "Button Primary sin icono").
///
/// [show] resolves to `null` when the sheet was dismissed via its standard
/// gesture (swipe down / tap on the scrim) rather than a button — the caller
/// must still treat that as "seen" (criterion 3), so every call site marks
/// the tutorial seen unconditionally after `await`ing this, regardless of
/// the result.
class TutorialSheet extends StatelessWidget {
  const TutorialSheet({required this.content, super.key});

  final TutorialContent content;

  static Future<TutorialSheetResult?> show(
    BuildContext context,
    TutorialContent content,
  ) =>
      BottomSheetBase.show<TutorialSheetResult>(
        context,
        builder: (context) => TutorialSheet(content: content),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasCta = content.hasNavigationCta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                TutorialIcons.iconFor(content.iconName),
                color: colors.primaryOnSoft,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                content.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < content.points.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                TutorialSheetPointRow(
                  point: content.points[i],
                  showDivider: i < content.points.length - 1,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (hasCta) ...[
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(TutorialSheetResult.cta),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.plus, size: 18, color: colors.onPrimary),
                const SizedBox(width: 8),
                Text(content.ctaLabel!),
              ],
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () =>
                Navigator.of(context).pop(TutorialSheetResult.gotIt),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  l10n.tutorialGotIt,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ] else
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(TutorialSheetResult.gotIt),
            child: Text(l10n.tutorialGotIt),
          ),
      ],
    );
  }
}

/// A single bullet of a [TutorialSheet]: a bullet badge, a bold heading and
/// its body copy — a row inside the shared "Points Card" container.
class TutorialSheetPointRow extends StatelessWidget {
  const TutorialSheetPointRow({
    required this.point,
    this.showDivider = false,
    super.key,
  });

  final TutorialPoint point;

  /// Whether this row draws the bottom divider that separates it from the
  /// next point — the last point in a card never has one.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            '•',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.primaryOnSoftStrong,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                point.heading,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                point.body,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!showDivider) {
      return row;
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: row,
    );
  }
}
