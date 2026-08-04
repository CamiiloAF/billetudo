import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The shared "Ver más" affordance: a full-width `$muted` pill with the
/// shared label and a `chevron-down`, never a bare text button. Used by
/// Presupuestos, Deudas, Metas and Pagos programados to expand a paginated
/// list in place — it never navigates away, which is why it points down
/// instead of forward.
///
/// While [loading] is true it shows a small spinner instead of the chevron
/// and its tap is disabled, for features (Pagos programados) whose "load
/// more" hits the repository instead of just slicing an in-memory list.
class LoadMoreButton extends StatelessWidget {
  const LoadMoreButton({
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final VoidCallback onPressed;

  /// Whether a page is currently being fetched. Disables the tap and shows a
  /// spinner in place of the chevron.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return Material(
      color: colors.muted,
      borderRadius: BorderRadius.circular(AppTheme.radiusField),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.commonLoadMore,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryOnSoftStrong,
                ),
              ),
              const SizedBox(width: 6),
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primaryOnSoftStrong,
                  ),
                )
              else
                Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: colors.primaryOnSoftStrong,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
