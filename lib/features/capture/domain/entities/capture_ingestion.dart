import 'package:equatable/equatable.dart';

import 'parsed_capture.dart';

/// One [ParsedCapture] plus the suggestions the domain already resolved for
/// it, ready to be written to the inbox.
///
/// The suggestions travel separately from the parsed fields on purpose: the
/// parser produced [ParsedCapture], while `suggestedAccountId` and
/// `suggestedCategoryId` are the app's own guesses (last-4 lookup and
/// merchant learning). Keeping them apart is what stops a guess from ever
/// being mistaken for something the bank actually said.
class CaptureIngestion extends Equatable {
  const CaptureIngestion({
    required this.parsed,
    this.suggestedAccountId,
    this.suggestedCategoryId,
  });

  final ParsedCapture parsed;
  final String? suggestedAccountId;
  final String? suggestedCategoryId;

  @override
  List<Object?> get props => [parsed, suggestedAccountId, suggestedCategoryId];
}
