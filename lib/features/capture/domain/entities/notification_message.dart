import 'package:equatable/equatable.dart';

/// One notification handed to the parser, already reduced to the only three
/// things the rules look at: which app sent it, its title and its body.
///
/// **This object never leaves memory.** It is built inside the parser call and
/// discarded when the call returns; nothing that holds [title] or [text] may
/// be written to Drift, to `SharedPreferences`, to a log or to a crash report
/// (zero retention, HU-03 of
/// `docs/requirements/fase-2/19-notificaciones-bancarias.md`). Only the fields
/// a rule identified survive, in `ParsedNotification`.
class NotificationMessage extends Equatable {
  const NotificationMessage({
    required this.packageName,
    required this.postedAt,
    this.title = '',
    this.text = '',
  });

  /// Android `packageName` of the emitting app. The only field read before the
  /// issuer filter runs — see `IssuerFilter` on the Kotlin side.
  final String packageName;

  /// `EXTRA_TITLE`.
  final String title;

  /// `EXTRA_BIG_TEXT` when present, `EXTRA_TEXT` otherwise. The collapsed row
  /// the user sees is truncated with an ellipsis; the extras are not, and the
  /// rules are written against the extras.
  final String text;

  /// When Android posted the notification. Becomes `postedAt` on the capture
  /// when the text carries no explicit date, which is the common case.
  final DateTime postedAt;

  /// Title and body joined by a newline, the surface a `RuleTarget.combined`
  /// regex matches against. The newline is meaningful: Nu splits the amount
  /// (title) from the counterparty (body), so rules cross it explicitly.
  String get combined => '$title\n$text';

  @override
  List<Object?> get props => <Object?>[packageName, title, text, postedAt];
}
