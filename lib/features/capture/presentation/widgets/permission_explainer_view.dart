import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import 'permission_explainer_body.dart';

/// `FRtfP`'s content: the explainer body, then the two ways out anchored at
/// the bottom of the screen (HU-01).
///
/// **Two exits, always.** One goes to Android's settings; the other declines
/// without cost. A single-exit flow for a permission this invasive would be
/// coercive, and the rest of the app works untouched without it.
///
/// The CTAs sit outside the scroll view so the decline is never below the
/// fold: an option the user has to scroll to find is not really offered.
class PermissionExplainerView extends StatelessWidget {
  const PermissionExplainerView({
    required this.onOpenSettings,
    required this.onDecline,
    super.key,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        const Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: PermissionExplainerBody(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(LucideIcons.externalLink, size: 18),
                label: Text(l10n.capturePermissionOpenSettingsCta),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onDecline,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(l10n.capturePermissionDeclineCta),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
