import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';

/// A generic "Próximamente" bottom sheet: icon orb + "Próximamente" title +
/// message + optional "no es asesoría financiera" disclaimer + "Entendido".
///
/// Reused across the app for features that are announced but not yet built
/// (the Home's bell and AI banner, HU-06/HU-07). It never runs anything — it
/// only informs — so it never touches Nivel 0.
class ComingSoonSheet extends StatelessWidget {
  const ComingSoonSheet({
    required this.icon,
    required this.message,
    this.disclaimer,
    super.key,
  });

  final IconData icon;

  /// Already localized.
  final String message;

  /// Only the AI sheet carries the "no es asesoría financiera" disclaimer;
  /// the notifications sheet passes `null`.
  final String? disclaimer;

  static Future<void> show(
    BuildContext context, {
    required IconData icon,
    required String message,
    String? disclaimer,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => ComingSoonSheet(
          icon: icon,
          message: message,
          disclaimer: disclaimer,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final disclaimer = this.disclaimer;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.primaryOnSoft, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.comingSoonTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            if (disclaimer != null) ...[
              const SizedBox(height: 8),
              Text(
                disclaimer,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.textSecondary),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.comingSoonUnderstood),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
