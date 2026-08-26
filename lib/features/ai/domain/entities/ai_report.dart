import 'package:equatable/equatable.dart';

/// What the person found wrong with a generated message.
///
/// A closed list, not free text, so the UI offers options instead of an empty
/// box that invites pasting personal data into a server-side table.
enum AiReportReason { offensive, wrong, harmful, privacy, other }

/// One report of a message the assistant generated.
///
/// **This is the single exception to "nothing from a conversation reaches a
/// server."** The rest of the assistant is built so that promise is structural
/// (the broker is stateless, the transcript lives only in Drift), and the
/// privacy policy states it in §17.5.
///
/// The exception exists because Google Play's AI-Generated Content policy
/// requires in-app reporting of offensive output *without leaving the app* —
/// its absence is grounds for removal, not just rejection — and "without
/// leaving the app" rules out the obvious alternative of opening a mail client
/// with the text pre-filled.
///
/// What keeps it from contradicting the promise is that it is **requested
/// retention, not silent retention**:
///
///  - nothing is ever sent automatically; only a tap on "reportar" writes a
///    row;
///  - only [reportedText], the single message being reported, travels — never
///    the conversation around it;
///  - the UI must say so *before* sending. Without that notice, §17.5 of the
///    policy is simply false.
///
/// Those three properties are the justification. Preserve them if this is
/// ever touched.
class AiReport extends Equatable {
  const AiReport({
    required this.reason,
    required this.reportedText,
    required this.clientVersion,
    this.conversationId,
    this.comment,
  });

  final AiReportReason reason;

  /// The assistant message being reported, verbatim. The only conversation
  /// content that exists on a server.
  final String reportedText;

  /// `1.12.0+134`. Lets a wave of reports be tied to the build that caused it.
  final String clientVersion;

  /// Groups reports from the same thread without carrying the thread itself.
  final String? conversationId;

  /// The person's own words, optional. Never required — a report has to be one
  /// tap away or it does not get used.
  final String? comment;

  @override
  List<Object?> get props =>
      [reason, reportedText, clientVersion, conversationId, comment];
}
