import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// `Sync Hero` (`XxHV3`): the block that carries the whole state — what is
/// happening, since when, what it would cost, and the one action available.
///
/// The attention treatment is a **background** (`$amber-soft`) with no border:
/// with a border the block reads as "a card with an alert" instead of as a
/// different surface. The neutral states keep `$surface` + `$border`.
///
/// The CTA is a slot: it is replaced whole, never restyled, because the five
/// forms it takes across the family (neutral solid, neutral outlined, their
/// inert twins and the one violet "Iniciar sesión") differ in weight, not in
/// colour. No sync action is ever violet — in this screen violet means *the
/// cloud*.
///
/// [compact] is an optional parametrization for the Home "Tu cuenta" sheet's
/// sync block (`design-system/billetudo/pages/inicio.md` § "El bloque de
/// sync"), which the user explicitly required to reuse this exact component
/// rather than a parallel one. Absent (`compact: false`, the default), the
/// component renders exactly as it does across `sincronizacion.md`'s ~20
/// uses: unchanged padding/gap, [cta] rendered, no [trailingChevron]. With
/// `compact: true`: tighter padding/corner radius, [cta] dropped entirely
/// (the sheet's whole block is tappable instead, toward "Estado de
/// sincronización" — the real CTA lives on that full screen), and
/// [trailingChevron] draws a chevron so the block still has a visible
/// boundary (without it, and without a CTA, a borderless "sincronizado"
/// state read as loose text with no affordance at all).
class SyncHero extends StatelessWidget {
  const SyncHero({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.kicker,
    required this.body,
    required this.timeRow,
    this.cta,
    this.kickerColor,
    this.caption,
    this.attention = false,
    this.compact = false,
    this.trailingChevron = false,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  /// Already localized.
  final String title;

  /// Already localized.
  final String kicker;

  /// Already localized. The risk sentence: always in the conditional, never
  /// blaming anyone.
  final String body;

  final Widget timeRow;

  /// `null` only in [compact] mode — every full-screen use still supplies
  /// one.
  final Widget? cta;

  /// `$amber-text` in the attention states, `$text-secondary` elsewhere.
  final Color? kickerColor;

  /// Already localized. Only the offline state turns it on, to explain why
  /// the button is inert.
  final String? caption;

  /// Paints the `$amber-soft`, border-less treatment.
  final bool attention;

  /// Tighter padding/corner radius and no [cta] — see class doc.
  final bool compact;

  /// Only meaningful with [compact]: draws a trailing chevron so the block
  /// keeps a visible boundary once its CTA is gone.
  final bool trailingChevron;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final padding = compact ? 14.0 : 20.0;
    final gap = compact ? 10.0 : 12.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: attention ? colors.amberSoft : colors.surface,
        borderRadius: BorderRadius.circular(
          compact ? AppTheme.radiusMedium : AppTheme.radiusLarge,
        ),
        border: attention ? null : Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kicker,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kickerColor ?? colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (compact && trailingChevron) ...[
                const SizedBox(width: 8),
                Icon(LucideIcons.chevronRight, size: 18, color: colors.textSecondary),
              ],
            ],
          ),
          SizedBox(height: gap),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: gap),
          timeRow,
          if (cta case final cta?) ...[
            SizedBox(height: gap),
            SizedBox(width: double.infinity, child: cta),
          ],
          if (caption case final caption?) ...[
            SizedBox(height: gap),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
