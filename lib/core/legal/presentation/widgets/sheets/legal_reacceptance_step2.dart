import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../router/app_router.dart';
import '../../../../theme/app_colors.dart';
import '../../cubit/legal_reacceptance_cubit.dart';

/// Step 2 of the re-acceptance sheet (Pencil `f8KnrT`): the consequence of
/// "No acepto" plus the data-export escape hatch. Reachable with the app
/// blocked — `AppRoutes.exportCsv` renders on the root navigator and
/// `ExportCubit` needs no session, no network.
class LegalReacceptanceStep2 extends StatelessWidget {
  const LegalReacceptanceStep2({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final cubit = context.read<LegalReacceptanceCubit>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(
            LucideIcons.download,
            color: colors.primaryOnSoft,
            size: 26,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.legalReacceptanceStep2Title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: colors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.legalReacceptanceStep2Message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.exportCsv),
            icon: const Icon(LucideIcons.download),
            label: Text(l10n.legalReacceptanceStep2Export),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: cubit.backToStep1,
            icon: const Icon(LucideIcons.arrowLeft),
            label: Text(l10n.legalReacceptanceStep2Back),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.legalReacceptanceFootnote,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
        ),
      ],
    );
  }
}
