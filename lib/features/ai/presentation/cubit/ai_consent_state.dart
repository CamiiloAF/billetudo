import 'package:equatable/equatable.dart';

/// The AI assistant's third-party data-sharing consent gate (Apple 5.1.2(i)).
enum AiConsentStatus {
  /// Reading `AppSettings.aiConsentAcceptedAt` for the first time.
  checking,

  /// Not accepted yet — the consent screen blocks the composer.
  required,

  /// Accepted — the chat is usable.
  granted,
}

class AiConsentState extends Equatable {
  const AiConsentState({
    this.status = AiConsentStatus.checking,
    this.accepting = false,
  });

  final AiConsentStatus status;

  /// True while `accept()`'s write is in flight, so the CTA can show a
  /// spinner instead of accepting a second tap mid-write.
  final bool accepting;

  AiConsentState copyWith({AiConsentStatus? status, bool? accepting}) =>
      AiConsentState(
        status: status ?? this.status,
        accepting: accepting ?? this.accepting,
      );

  @override
  List<Object?> get props => [status, accepting];
}
