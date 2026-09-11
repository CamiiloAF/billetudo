import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../core/widgets/permission_fact_row.dart';

/// The microphone explainer (`tN3NS`), which doubles as the in-context
/// pre-prompt (HU-07).
///
/// It is shown **before** the system dialog the first time — on iOS that
/// dialog appears exactly once, and a "Don't allow" there is effectively
/// irreversible for most people — and reused whenever the permission is
/// missing afterwards. It is never a dead end: "Escribir a mano" opens the
/// full manual form, which is Nivel 0 and cannot depend on a permission.
///
/// The primary CTA changes with what is actually possible: while the system
/// can still be asked it asks, and once the answer is permanent it stops
/// nagging and offers the settings shortcut instead. That branch is not drawn
/// in the frame, which only shows the "already denied" case.
class VoiceCapturePermissionBody extends StatelessWidget {
  const VoiceCapturePermissionBody({
    required this.canRequest,
    required this.onRequest,
    required this.onOpenSettings,
    required this.onWriteByHand,
    super.key,
  });

  /// Whether the system dialog can still be shown.
  final bool canRequest;

  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;
  final VoidCallback onWriteByHand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.micOff,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: l10n.captureVoicePermissionTitle,
          message: l10n.captureVoicePermissionMessage,
          messageColor: colors.textSecondary,
        ),
        const SizedBox(height: 16),
        PermissionFactList(
          facts: [
            PermissionFactRow(
              icon: LucideIcons.mic,
              title: l10n.captureVoicePermissionFact1Title,
              body: l10n.captureVoicePermissionFact1Body,
            ),
            PermissionFactRow(
              icon: LucideIcons.shieldCheck,
              title: l10n.captureVoicePermissionFact2Title,
              body: l10n.captureVoicePermissionFact2Body,
            ),
            PermissionFactRow(
              icon: LucideIcons.pencilLine,
              title: l10n.captureVoicePermissionFact3Title,
              body: l10n.captureVoicePermissionFact3Body,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: canRequest ? onRequest : onOpenSettings,
          icon: Icon(
            canRequest ? LucideIcons.mic : LucideIcons.settings,
            size: 18,
          ),
          label: Text(
            canRequest
                ? l10n.captureVoicePermissionAllow
                : l10n.captureVoicePermissionOpenSettings,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onWriteByHand,
          icon: const Icon(LucideIcons.pencilLine, size: 18),
          label: Text(l10n.captureVoiceWriteByHand),
        ),
      ],
    );
  }
}
