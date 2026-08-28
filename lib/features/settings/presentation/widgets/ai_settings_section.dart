import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/legal_urls.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/utils/external_url_opener.dart';
import '../cubit/app_settings_cubit.dart';
import '../cubit/app_settings_state.dart';
import 'ai_consent_withdraw_field.dart';
import 'ai_notes_access_field.dart';
import 'legal_link_field.dart';
import 'settings_section_label.dart';
import 'sheets/ai_consent_withdraw_sheet.dart';
import 'sheets/ai_notes_access_sheet.dart';

/// The "Asistente de IA" block of Ajustes: the notes-access opt-in plus the
/// public legal links (privacy policy and terms of use), which live here
/// because this is the section where a third party — Google Gemini — enters
/// the picture.
///
/// No `billetudo.pen` frame covers this block yet (`aaQBp`/`jDaUb` predate
/// the assistant), so it is built out of the section's existing pieces —
/// `AiNotesAccessField` mirrors "Mostrar ayuda al entrar a una sección",
/// `LegalLinkField` is `SettingsField` (`R8PlN`) — instead of new shapes.
class AiSettingsSection extends StatelessWidget {
  const AiSettingsSection({this.openUrl = openExternalUrl, super.key});

  /// Injected down to [LegalLinkField] so widget tests never reach the
  /// `url_launcher` platform channel.
  final ExternalUrlOpener openUrl;

  /// Applies the requested value of "Dejar que el asistente lea mis notas".
  ///
  /// Turning it **on** asks for an explicit confirmation first, because it is
  /// what starts sending the free-text note to a third party. Turning it off
  /// applies immediately: withdrawing a permission never asks twice.
  Future<void> _onChanged(BuildContext context, {required bool enabled}) async {
    final cubit = context.read<AppSettingsCubit>();
    if (!enabled) {
      await cubit.setAiNotesAccessEnabled(enabled: false);
      return;
    }
    final confirmed = await AiNotesAccessSheet.show(context);
    if (confirmed ?? false) {
      await cubit.setAiNotesAccessEnabled(enabled: true);
    }
  }

  /// Withdraws the assistant's data-sharing consent (RGPD art. 7.3), after an
  /// explicit confirmation: unlike turning the notes switch off, this closes
  /// the assistant entirely and takes the notes opt-in down with it, so the
  /// consequences are stated before it happens — not because withdrawing is
  /// discouraged.
  Future<void> _onWithdraw(BuildContext context) async {
    final cubit = context.read<AppSettingsCubit>();
    final confirmed = await AiConsentWithdrawSheet.show(context);
    if (confirmed ?? false) {
      await cubit.clearAiConsent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionLabel(l10n.settingsAiSection),
        BlocBuilder<AppSettingsCubit, AppSettingsState>(
          builder: (context, settings) => AiNotesAccessField(
            enabled: settings.aiNotesAccessEnabled,
            onChanged: (value) => unawaited(
              _onChanged(context, enabled: value),
            ),
          ),
        ),
        // Only while there IS a consent to withdraw: before accepting, this
        // row would name a permission the person never gave.
        BlocBuilder<AppSettingsCubit, AppSettingsState>(
          buildWhen: (previous, current) =>
              previous.hasAcceptedAiConsent != current.hasAcceptedAiConsent,
          builder: (context, settings) => settings.hasAcceptedAiConsent
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AiConsentWithdrawField(
                    onTap: () => unawaited(_onWithdraw(context)),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        LegalLinkField(
          icon: LucideIcons.shieldCheck,
          label: l10n.settingsPrivacyPolicy,
          sublabel: l10n.settingsPrivacyPolicySubtitle,
          url: LegalUrls.privacyPolicy,
          openUrl: openUrl,
        ),
        LegalLinkField(
          icon: LucideIcons.fileText,
          label: l10n.settingsTermsOfUse,
          sublabel: l10n.settingsTermsOfUseSubtitle,
          url: LegalUrls.termsOfUse,
          openUrl: openUrl,
        ),
      ],
    );
  }
}
