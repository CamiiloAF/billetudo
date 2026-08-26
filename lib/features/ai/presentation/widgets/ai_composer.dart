import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/ai_chat_cubit.dart';
import '../cubit/ai_chat_state.dart';

/// The chat's input pill + Send button (`billetudo.pen` `M4AlIP`).
///
/// The Send button's `opacity:0.4`/`1` toggle (`qnhSI`/`hAZza`) is driven by
/// `AiChatState.canSend`, so it always matches what a tap would actually do —
/// disabled while empty or a turn is already in flight, enabled the instant
/// there is text to send.
class AiComposer extends StatefulWidget {
  const AiComposer({super.key});

  @override
  State<AiComposer> createState() => _AiComposerState();
}

class _AiComposerState extends State<AiComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final cubit = context.read<AiChatCubit>();
    if (!cubit.state.canSend) {
      return;
    }
    unawaited(cubit.send());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: colors.surface,
      child: Column(
        children: [
          ColoredBox(
            color: colors.border,
            child: const SizedBox(height: 1, width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _controller,
                      onChanged: context.read<AiChatCubit>().updateDraft,
                      onSubmitted: (_) => _send(context),
                      textInputAction: TextInputAction.send,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: l10n.aiChatComposerHint,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.segmentInactiveText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                BlocBuilder<AiChatCubit, AiChatState>(
                  buildWhen: (previous, current) =>
                      previous.canSend != current.canSend,
                  builder: (context, state) => Opacity(
                    opacity: state.canSend ? 1 : 0.4,
                    child: Material(
                      color: colors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: state.canSend ? () => _send(context) : null,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            LucideIcons.send,
                            size: 18,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
