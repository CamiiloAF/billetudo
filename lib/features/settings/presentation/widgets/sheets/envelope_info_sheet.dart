import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../envelope_info_bullet.dart';

/// Explains "Modo sobres" in plain language (HU-06), with no jargon
/// ("base-cero"/"YNAB"/"zero-based" never appear). Opened from the "¿Qué es?"
/// link in Ajustes, from the list's "⋮" menu and from the envelope hero's info
/// button. Purely informational — no destructive action, so it wears the
/// neutral `$primary` family, and every block is left-aligned (`eBwb0`).
///
/// Besides explaining, it converts: the primary button turns the mode on. When
/// the mode is already on ([envelopeEnabled]) that button would be nonsense, so
/// it is hidden and only "Entendido" remains — `billetudo.pen` has no frame for
/// that case, so this is a decision taken here, not a designed state.
class EnvelopeInfoSheet extends StatelessWidget {
  const EnvelopeInfoSheet({this.envelopeEnabled = false, super.key});

  final bool envelopeEnabled;

  /// Resolves to `true` when the user asks to turn envelope mode on.
  static Future<bool?> show(
    BuildContext context, {
    bool envelopeEnabled = false,
  }) =>
      BottomSheetBase.show<bool>(
        context,
        builder: (context) =>
            EnvelopeInfoSheet(envelopeEnabled: envelopeEnabled),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                Icon(LucideIcons.target, color: colors.primaryOnSoft, size: 24),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.envelopeInfoTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.envelopeInfoBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        EnvelopeInfoBullet(text: l10n.envelopeInfoBulletJobs),
        const SizedBox(height: 10),
        EnvelopeInfoBullet(text: l10n.envelopeInfoBulletZero),
        const SizedBox(height: 14),
        Text(
          l10n.envelopeInfoReassure,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        if (!envelopeEnabled) ...[
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.target),
            label: Text(l10n.envelopeInfoActivate),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.envelopeInfoGotIt),
        ),
      ],
    );
  }
}
