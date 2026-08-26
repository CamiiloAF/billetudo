import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/ai_consent_cubit.dart';
import '../cubit/ai_consent_state.dart';

/// The AI assistant's data-sharing consent gate (Apple 5.1.2(i)): shown in
/// place of the chat until `AppSettings.aiConsentAcceptedAt` is set, naming
/// Google explicitly per `docs/legal/politica-de-privacidad.md` §17.
///
/// No `billetudo.pen` frame exists for this screen yet
/// (`asistente-ia.md`'s "Pendientes" only covers the chat/history flows) —
/// it follows the app's existing icon-circle-title-body-CTA layout
/// (`EmptyState`'s own shape) rather than a new one-off, and should go
/// through Pencil in a follow-up pass instead of staying a one-off.
class AiConsentPage extends StatelessWidget {
  const AiConsentPage({required this.onDecline, super.key});

  /// Called when the user backs out without accepting (there is nothing
  /// useful to show underneath, so this closes the assistant entirely).
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: l10n.aiConsentTitle, onBack: onDecline),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: colors.primarySoft,
                          borderRadius: BorderRadius.circular(44),
                        ),
                        child: Icon(
                          LucideIcons.sparkles,
                          size: 40,
                          color: colors.primaryOnSoft,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.aiConsentHeadline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.aiConsentBody,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<AiConsentCubit, AiConsentState>(
                        builder: (context, state) => SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state.accepting
                                ? null
                                : () => unawaited(
                                      context.read<AiConsentCubit>().accept(),
                                    ),
                            child: state.accepting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.aiConsentAccept),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: onDecline,
                        child: Text(l10n.aiConsentDecline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
