import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';

/// Explains "Modo sobres" in plain language (HU-06), with no jargon
/// ("base-cero"/"YNAB"/"zero-based" never appear). Opened from the "¿Qué es?"
/// link next to the toggle in Ajustes. Purely informational — no destructive
/// action, so it wears the neutral `$primary` family.
class EnvelopeInfoSheet extends StatelessWidget {
  const EnvelopeInfoSheet({super.key});

  static Future<void> show(BuildContext context) => BottomSheetBase.show<void>(
        context,
        builder: (context) => const EnvelopeInfoSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(28),
          ),
          child:
              Icon(LucideIcons.target, color: colors.primaryOnSoft, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.envelopeInfoTitle,
          textAlign: TextAlign.center,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.envelopeInfoBody,
          textAlign: TextAlign.center,
          style:
              theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.envelopeInfoGotIt),
          ),
        ),
      ],
    );
  }
}
