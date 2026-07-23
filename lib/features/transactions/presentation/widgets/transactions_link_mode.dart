import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Turns Movimientos into "link mode" (`g0x859`, Deudas HU-02): the same list,
/// but with a banner naming the debt, the FAB hidden, and every row tap
/// attributing that movement to the debt instead of opening its detail.
///
/// A plain value object so `TransactionsPage` stays decoupled from the Deudas
/// feature — the router builds this with callbacks wired to the debt link
/// cubit, and the page only reads it.
@immutable
class TransactionsLinkMode {
  const TransactionsLinkMode({
    required this.debtLabel,
    required this.onCancel,
    required this.onLinkTransaction,
  });

  /// Already localized debt context, e.g. "Crédito vehicular · Yo debo".
  final String debtLabel;

  /// Cancels link mode (the banner's "x").
  final VoidCallback onCancel;

  /// Attributes the tapped transaction to the debt and returns once done.
  final Future<void> Function(String transactionId) onLinkTransaction;
}

/// The `$primary-soft` banner (`Y71NB`) shown at the top of the list in link
/// mode: a `link-2` glyph, the "Enlazar a …" prompt, and an "x" to cancel.
class TransactionsLinkBanner extends StatelessWidget {
  const TransactionsLinkBanner({required this.linkMode, super.key});

  final TransactionsLinkMode linkMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                LucideIcons.link2,
                size: 18,
                color: colors.primaryOnSoftStrong,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.debtLinkBannerTitle(linkMode.debtLabel),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.primaryOnSoftStrong,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.debtLinkBannerBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.hintText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: linkMode.onCancel,
              tooltip: l10n.debtLinkCancelTooltip,
              iconSize: 20,
              color: colors.primaryOnSoftStrong,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: const Icon(LucideIcons.x),
            ),
          ],
        ),
      ),
    );
  }
}
