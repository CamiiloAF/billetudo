import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_cubit.dart';
import '../../../../core/widgets/segmented_control.dart';

/// The "Apariencia" card in Ajustes (Pencil `h4jCV`/`B0uqd` light theme,
/// `onPZR`/`eabgk` dark): icon-wrap + label header, with a `Segmented
/// Control` (`hFu41`) below offering Claro/Oscuro/Sistema.
///
/// Unlike `SettingsField`, this card is not a navigation row — it applies the
/// chosen [ThemeMode] immediately (no sheet, no confirmation), reading and
/// writing through [ThemeModeCubit].
class AppearanceField extends StatelessWidget {
  const AppearanceField({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.muted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.sunMoon,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.settingsAppearance,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<ThemeModeCubit, ThemeMode>(
            builder: (context, mode) => SegmentedControl<ThemeMode>(
              segments: [
                SegmentedControlOption(
                  value: ThemeMode.light,
                  label: l10n.settingsAppearanceLight,
                ),
                SegmentedControlOption(
                  value: ThemeMode.dark,
                  label: l10n.settingsAppearanceDark,
                ),
                SegmentedControlOption(
                  value: ThemeMode.system,
                  label: l10n.settingsAppearanceSystem,
                ),
              ],
              selected: mode,
              onChanged: (value) => unawaited(
                context.read<ThemeModeCubit>().setThemeMode(value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
