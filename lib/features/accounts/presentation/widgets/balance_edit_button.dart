import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The subtle "Ajustar saldo" affordance (Mejora #1): a small grey pencil next
/// to a balance figure.
///
/// Deliberately quiet — `$text-secondary`, 18px glyph — so it never competes
/// with the brand-violet header pencil that edits the whole account. Its 40px
/// tap target keeps it reachable without inflating its visual weight.
class BalanceEditButton extends StatelessWidget {
  const BalanceEditButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: AppLocalizations.of(context).accountBalanceAdjustTitle,
      iconSize: 18,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(foregroundColor: context.colors.textSecondary),
      icon: const Icon(LucideIcons.pencil),
    );
  }
}
