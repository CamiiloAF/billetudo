import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../improvement/presentation/widgets/notice_card.dart';

/// `VW54R` / `DSCf0` — the state card at the top of the captures section when
/// background capture may have stopped (HU-09).
///
/// Reuses `Notice Card · Con acción` (`cYVQm`) with the attention overrides:
/// `$amber-soft`/`$amber-text` on the shield icon, the card's own copy and
/// "Revisar" / "Ahora no" as its two actions. Three subtitle lines are allowed
/// here, unlike the notice cards this component was built for: the sentence
/// explains the phone's behaviour and cannot be shortened without losing the
/// part that makes the card make sense.
///
/// Tone: it states a fact about the phone, never a failure of the user. It
/// also never claims capture stopped — "puede detenerse" — because the app
/// cannot know for sure that the listener is dead.
class CaptureDegradedCard extends StatelessWidget {
  const CaptureDegradedCard({
    required this.onReview,
    required this.onSnooze,
    super.key,
  });

  /// Opens the sheet with the two system settings. It never fixes anything
  /// here: the settings live outside the app.
  final VoidCallback onReview;

  /// "Ahora no": hides the card for fourteen days, changes nothing else.
  final VoidCallback onSnooze;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;

    return NoticeCard(
      icon: LucideIcons.shieldAlert,
      iconColor: colors.amberText,
      iconBackground: colors.amberSoft,
      title: l10n.captureBackgroundCardTitle,
      subtitle: l10n.captureBackgroundCardSubtitle,
      subtitleMaxLines: 3,
      primaryActionLabel: l10n.captureBackgroundReviewCta,
      onPrimaryAction: onReview,
      secondaryActionLabel: l10n.captureBackgroundSnoozeCta,
      onSecondaryAction: onSnooze,
    );
  }
}
