import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../domain/entities/issuer_app.dart';
import '../utils/issuer_presentation.dart';

/// `Issuer Switch Row` (`HZ4F5`, `reusable:true`): one candidate bank app plus
/// its switch, **off by default** (HU-02).
///
/// The whole row is the tap target, not just the 48x28 [AppSwitch], which on
/// its own falls under the 44x44 minimum — the same accessibility rule
/// `ToggleField` follows.
///
/// The subtitle says what is read from that app, never the `packageName`: a
/// technical string tells the user nothing about what they are agreeing to.
class IssuerSwitchRow extends StatelessWidget {
  const IssuerSwitchRow({
    required this.issuer,
    required this.onChanged,
    super.key,
  });

  final IssuerApp issuer;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);
    final IssuerVisual visual = IssuerPresentation.visual(
      issuer.issuerId,
      colors,
    );

    return Semantics(
      toggled: issuer.enabled,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: InkWell(
          onTap: () => onChanged(!issuer.enabled),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: visual.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(visual.icon, size: 20, color: visual.foreground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        // Brand name, straight from the catalog: never
                        // translated and never invented here.
                        issuer.displayName,
                        // The frame's names are all short ("Nu", "Nequi"), so
                        // nothing wraps there. A longer catalog entry must
                        // not push the switch off the row.
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        IssuerPresentation.description(issuer.issuerId, l10n),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Visual only: the row above owns the gesture, so the switch
                // must not swallow the tap that lands directly on it.
                ExcludeSemantics(child: AppSwitch(value: issuer.enabled)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
