import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';

/// A generic "Próximamente" full page: icon orb + "Próximamente" + a short,
/// positive message. Reused as the placeholder for tabs and hubs whose feature
/// does not exist yet (Presupuestos, Metas, and the future destinations under
/// "Más"). Deliberately not a per-feature scaffold — those features are empty
/// on purpose until their own lote.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage(
      {required this.title, this.showAppBar = true, super.key});

  /// The screen title, already localized (e.g. "Presupuestos").
  final String title;

  /// Tab destinations render their own title inline; stacked pages (opened
  /// from "Más") get an app bar with a back button.
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!showAppBar) ...[
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 24),
                ],
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(44),
                  ),
                  child: Icon(
                    LucideIcons.rocket,
                    size: 40,
                    color: colors.primaryOnSoft,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.comingSoonTitle,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.comingSoonMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
