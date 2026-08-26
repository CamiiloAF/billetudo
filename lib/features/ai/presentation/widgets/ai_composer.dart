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

  /// Keeps the field in sync when the draft changes from outside typing —
  /// today, only `AiEmptyState`'s suggestion chips filling it in. Guarded by
  /// the equality check so it never fights the user's own keystrokes, which
  /// already reach `state.draft` through [_AiComposerState.build]'s
  /// `onChanged` and would otherwise round-trip back here on every char.
  void _syncDraft(String draft) {
    if (_controller.text == draft) {
      return;
    }
    _controller.value = _controller.value.copyWith(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
      composing: TextRange.empty,
    );
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

    return BlocListener<AiChatCubit, AiChatState>(
      listenWhen: (previous, current) => previous.draft != current.draft,
      listener: (context, state) => _syncDraft(state.draft),
      child: ColoredBox(
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
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.muted,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      // `Container.alignment` centers the field within the
                      // 44px `minHeight` floor for a single line — without
                      // it, `Align` (which `Container` only inserts when
                      // `alignment` is set) is skipped, and the extra room
                      // `ConstrainedBox` adds beyond the padded `TextField`'s
                      // own intrinsic height lands entirely below the text
                      // instead of splitting evenly, reading as leftover
                      // dead space under a single line.
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: _controller,
                        onChanged: context.read<AiChatCubit>().updateDraft,
                        onSubmitted: (_) => _send(context),
                        // `send` still lets most soft keyboards submit on
                        // Enter, matching the pre-multiline behaviour and
                        // this composer's single Send button (no separate
                        // newline key like WhatsApp's). Users who need a
                        // line break can still get one from keyboards that
                        // map a modifier to it; that's an acceptable
                        // trade-off over adding new composer chrome.
                        textInputAction: TextInputAction.send,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 6,
                        textCapitalization: TextCapitalization.sentences,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                        decoration: InputDecoration(
                          isDense: true,
                          // The app's global `InputDecorationTheme`
                          // (`app_theme.dart`) sets its own `enabledBorder`/
                          // `focusedBorder` (a 2px purple `OutlineInputBorder`
                          // with `radiusMedium`, meant for regular form fields).
                          // `InputDecorator` prefers those specific borders over
                          // the generic `border` below once the field is
                          // enabled/focused, so setting only `border:
                          // InputBorder.none` was not enough: on focus, the
                          // theme's smaller-radius purple outline painted on
                          // top of this pill's own 22px-radius `Container`,
                          // peeking out at the corners as a second, ghost
                          // input. All four variants have to be silenced
                          // explicitly.
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          filled: false,
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
      ),
    );
  }
}
