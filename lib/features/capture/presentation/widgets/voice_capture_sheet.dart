import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../domain/entities/spoken_transaction_draft.dart';
import '../cubit/voice_capture_cubit.dart';
import '../cubit/voice_capture_state.dart';
import '../utils/voice_locale_id.dart';
import 'voice_capture_cloud_consent_body.dart';
import 'voice_capture_listening_body.dart';
import 'voice_capture_no_amount_body.dart';
import 'voice_capture_permission_body.dart';
import 'voice_capture_unavailable_body.dart';

/// The one dictation sheet, shared by both triggers (long-pressing the Home
/// FAB and the "Dictar" pill of the movement form).
///
/// It resolves to a [SpokenTransactionDraft] when the user got somewhere —
/// including "Escribir a mano", which still carries the transcript so nothing
/// typed twice — and to `null` when they cancelled, in which case the caller
/// must do nothing at all.
///
/// **It never writes.** The sheet's whole output is a draft; opening the
/// prefilled form and pressing Guardar are the caller's and the user's jobs
/// (HU-01). And it keeps nothing: the cubit dies with the sheet, taking the
/// audio session and the transcript with it (HU-06).
class VoiceCaptureSheet extends StatefulWidget {
  const VoiceCaptureSheet({super.key});

  /// Opens the sheet.
  ///
  /// Dismissible by scrim and drag like every other sheet — a surface holding
  /// the microphone open is the last one that should be hard to escape. The
  /// session is not left running either way: disposing the sheet closes the
  /// cubit, which cancels the recognizer, so a swipe down is as complete a
  /// cancel as the button is.
  static Future<SpokenTransactionDraft?> show(BuildContext context) =>
      BottomSheetBase.show<SpokenTransactionDraft>(
        context,
        builder: (context) => const VoiceCaptureSheet(),
      );

  @override
  State<VoiceCaptureSheet> createState() => _VoiceCaptureSheetState();
}

class _VoiceCaptureSheetState extends State<VoiceCaptureSheet> {
  late final VoiceCaptureCubit _cubit = getIt<VoiceCaptureCubit>();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    // The permission is asked for here, in context, at the moment the user
    // triggered the capture — never at startup (HU-07).
    final appLocale = Localizations.localeOf(context);
    final deviceLocale = View.of(context).platformDispatcher.locale;
    unawaited(
      _cubit.start(
        localeId: VoiceLocaleId.resolve(appLocale, deviceLocale),
        languageCode: appLocale.languageCode,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  void _close([SpokenTransactionDraft? draft]) {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(draft);
  }

  Future<void> _declineAndWriteByHand() async {
    final draft = _cubit.draftForManualEntry();
    await _cubit.declineCloudTranscription();
    _close(draft);
  }

  Future<void> _cancel() async {
    await _cubit.cancel();
    _close();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VoiceCaptureCubit>.value(
      value: _cubit,
      child: BlocConsumer<VoiceCaptureCubit, VoiceCaptureState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == VoiceCaptureStatus.completed) {
            _close(state.draft);
          }
        },
        builder: (context, state) => switch (state.status) {
          VoiceCaptureStatus.preparing ||
          VoiceCaptureStatus.listening =>
            VoiceCaptureListeningBody(
              state: state,
              onCancel: () => unawaited(_cancel()),
              onDone: () => unawaited(_cubit.stopListening()),
            ),
          VoiceCaptureStatus.permissionNeeded => VoiceCapturePermissionBody(
              canRequest: state.isPermissionAskable,
              onRequest: () => unawaited(_cubit.requestPermission()),
              onOpenSettings: () => unawaited(_cubit.openSystemSettings()),
              onWriteByHand: () => _close(_cubit.draftForManualEntry()),
            ),
          VoiceCaptureStatus.cloudConsentNeeded =>
            VoiceCaptureCloudConsentBody(
              onAllow: () => unawaited(_cubit.allowCloudTranscription()),
              // The refusal is persisted before the sheet closes, so the next
              // "Dictar" honours it instead of asking again.
              onWriteByHand: () => unawaited(_declineAndWriteByHand()),
            ),
          VoiceCaptureStatus.noAmount => VoiceCaptureNoAmountBody(
              transcript: state.transcript,
              onRetry: () => unawaited(_cubit.retry()),
              onWriteByHand: () => _close(_cubit.draftForManualEntry()),
            ),
          VoiceCaptureStatus.unavailable => VoiceCaptureUnavailableBody(
              reason: state.unavailableReason,
              onRetry: () => unawaited(_cubit.retry()),
              onWriteByHand: () => _close(_cubit.draftForManualEntry()),
            ),
          // Handed back by the listener above; this frame just avoids a flash
          // of empty space while the pop settles.
          VoiceCaptureStatus.completed => const SizedBox.shrink(),
        },
      ),
    );
  }
}
