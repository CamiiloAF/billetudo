import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../cubit/capture_background_cubit.dart';
import '../../cubit/capture_background_state.dart';
import '../../utils/capture_presentation.dart';
import '../capture_background_action_row.dart';

/// `TPLPN` / `bN2YZ` — the sheet behind "Revisar" and "Revisar captura"
/// (HU-09).
///
/// It is the only surface that touches the system: the battery-optimization
/// exemption and the manufacturer's autostart screen. The app **cannot grant
/// either setting**, so this sheet never claims success from a tap — it opens
/// the screen and re-reads the real state when the user comes back.
///
/// Two rows at most:
///  1. battery exemption, always present; it turns into a fulfilled row once
///     Android reports the app as exempt;
///  2. autostart, **only** on manufacturers that expose a destination. Hiding
///     it elsewhere is deliberate: inventing a screen that does not exist on
///     the device would send the user somewhere useless.
///
/// "Listo, ya lo activé" calls `confirmActivated()` and closes only when the
/// real diagnostics say the battery exemption is granted; otherwise the sheet
/// stays open with freshly read rows. Scrim or drag simply closes it — that
/// is not a "no", and only "Ahora no" snoozes.
class CaptureBackgroundSheet extends StatelessWidget {
  const CaptureBackgroundSheet({super.key});

  /// Opens the sheet on the root navigator, carrying the page's cubit so the
  /// rows keep re-reading the same state the card is watching.
  static Future<void> show(BuildContext context) {
    final CaptureBackgroundCubit cubit = context.read<CaptureBackgroundCubit>();
    return BottomSheetBase.show<void>(
      context,
      builder: (BuildContext sheetContext) =>
          BlocProvider<CaptureBackgroundCubit>.value(
        value: cubit,
        child: const CaptureBackgroundSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);

    return BlocBuilder<CaptureBackgroundCubit, CaptureBackgroundState>(
      builder: (BuildContext context, CaptureBackgroundState state) {
        final CaptureBackgroundCubit cubit =
            context.read<CaptureBackgroundCubit>();
        final bool batteryExempt = state.batteryOptimizationExempt;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.captureBackgroundSheetTitle,
              // 19/700, the sheet's own header: `SheetHead` is 17/700 and
              // this surface is one step above a picker.
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.captureBackgroundSheetBody,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            CaptureBackgroundActionRow(
              icon: LucideIcons.batteryCharging,
              iconColor: colors.amberText,
              iconBackground: colors.amberSoft,
              title: l10n.captureBackgroundBatteryTitle,
              subtitle: batteryExempt
                  ? l10n.captureBackgroundBatteryAllowed
                  : l10n.captureBackgroundBatterySubtitle,
              onTap: batteryExempt ? null : cubit.requestBatteryExemption,
            ),
            // Hidden, not disabled, when the manufacturer exposes no screen:
            // the spec forbids inventing a destination.
            if (state.autostartAvailable) ...<Widget>[
              const SizedBox(height: 10),
              CaptureBackgroundActionRow(
                icon: LucideIcons.rotateCw,
                iconColor: colors.primaryOnSoft,
                iconBackground: colors.primarySoft,
                title: l10n.captureBackgroundAutostartTitle,
                subtitle:
                    l10n.captureBackgroundAutostartSubtitle(state.manufacturer),
                onTap: cubit.openAutostart,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              captureBackgroundSheetFooterLabel(
                l10n,
                state.lastCaptureAt,
                localeName: Localizations.localeOf(context).toLanguageTag(),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // `TPLPN` stacks the two actions full width instead of the usual
            // `SheetButtonsRow`: the primary is the one that closes the sheet
            // after verifying the settings, so it reads first and gets the
            // whole width. The secondary sits below, 10pt apart.
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final bool resolved = await cubit.confirmActivated();
                  if (resolved && context.mounted) {
                    BottomSheetBase.dismiss(context);
                  }
                },
                child: Text(l10n.captureBackgroundConfirmCta),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  // Closes either way: a failed write must not trap the user
                  // in a sheet they asked to leave.
                  await cubit.snooze();
                  if (context.mounted) {
                    BottomSheetBase.dismiss(context);
                  }
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(l10n.captureBackgroundSnoozeCta),
              ),
            ),
          ],
        );
      },
    );
  }
}
