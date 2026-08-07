import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neutral_button.dart';

/// The shared progress pattern (`d9wzVg`/`xdG9q`, HU-09): real progress
/// (rows processed/total), cancellable, used identically for export, import
/// and restore — only the [iconColor]/[iconBackground] and [title] change per
/// flow.
///
/// **Blocking, not a dismissible sheet:** the caller must disable the scrim
/// and the back gesture while this is on screen (`PopScope` at the page
/// level) — the only way out is [onCancel], which also deletes the partial
/// file (HU-01/HU-03: never leave a truncated file that looks complete).
class BlockingProgressView extends StatelessWidget {
  const BlockingProgressView({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.processed,
    required this.total,
    this.onCancel,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  /// Already localized ("Importando tus movimientos…").
  final String title;

  final int processed;
  final int total;

  /// `null` hides the cancel button — used while the write is a single
  /// non-interruptible call at the data layer (no cancellation token
  /// exposed yet), so the UI never promises a cancel it cannot honor.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final ratio = total <= 0 ? 0.0 : (processed / total).clamp(0.0, 1.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: iconBackground, shape: BoxShape.circle),
              child: Icon(icon, size: 26, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.importExportProgressCaption(processed, total),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: colors.track,
                valueColor: AlwaysStoppedAnimation(colors.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.importExportProgressHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            if (onCancel case final onCancel?) ...[
              const SizedBox(height: 16),
              NeutralButton(
                label: l10n.commonCancel,
                icon: LucideIcons.x,
                onPressed: onCancel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
