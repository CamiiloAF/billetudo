import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';

/// `yqYfi` — the contextual offer of the notification permission (HU-01).
///
/// Shown **once**, right after the user saves their first manual expense, and
/// never in onboarding. Two reasons, both deliberate: the explainer is the
/// densest screen of the feature and drowns a brand-new user, and asking for
/// the most invasive permission on the phone before the app has earned any
/// trust is the worst possible conversion. Right after typing an expense by
/// hand, the user has just felt the friction this removes.
///
/// A small sheet on purpose — it is an offer, not another dense screen. The
/// full explanation lives behind "Ver cómo funciona".
///
/// **Copy rule (obligatory).** It states the *condition* — "cuando tu banco
/// te avise de una compra, te la dejo lista para confirmar" — and never
/// "¿quieres que esto aparezca solo?". The app cannot capture everything and
/// never will: cash sends no notification, banks exist outside the catalog,
/// and the system can kill the service. A promise of total automation breaks
/// on the first expense that does not show up, and the user concludes the
/// feature is broken. The closing line says so outright.
///
/// The way out carries the same visual weight as the CTA and sits on the
/// left: declining is a real answer, not a mistake to be nudged out of.
class CaptureOfferSheet extends StatelessWidget {
  const CaptureOfferSheet({super.key});

  /// Resolves `true` when the user wants to see how it works.
  static Future<bool?> show(BuildContext context) => BottomSheetBase.show<bool>(
        context,
        builder: (BuildContext context) => const CaptureOfferSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SheetMessage(
          icon: LucideIcons.bellRing,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: l10n.capturePermissionTitle,
          message: l10n.captureOfferMessage,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.captureOfferScopeNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Text(l10n.captureOfferDismissCta),
          ),
          right: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(LucideIcons.arrowRight, size: 18),
            label: Text(l10n.captureSeeHowItWorksCta),
          ),
        ),
      ],
    );
  }
}
