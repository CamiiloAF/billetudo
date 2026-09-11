import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction.dart';
import 'pending_capture.dart';

/// How much the app trusts a duplicate match (HU-07).
///  - [possible]: heuristic. Same amount and currency within a wide window,
///    against something the user may have typed by hand a day later. Shown as
///    "posible duplicado" so the user can compare and decide.
///  - [high]: same amount and currency within minutes, from a different
///    issuer — the wallet + bank pairing of one NFC payment. Presented
///    grouped as a single proposed movement.
///
/// Neither level ever authorizes the app to merge or discard on its own: a
/// false positive erases a real expense and silently unbalances the account,
/// which is worse than the duplicate it would have prevented.
enum DuplicateConfidence { possible, high }

/// Something already in the app that may be the same movement as the capture
/// being reviewed.
sealed class DuplicateCandidate extends Equatable {
  const DuplicateCandidate({required this.confidence});

  final DuplicateConfidence confidence;
}

/// A transaction the user already recorded (by hand, imported, or generated
/// by a scheduled payment) that matches the capture. Always `possible`: the
/// user may legitimately have bought two identical coffees.
final class TransactionDuplicateCandidate extends DuplicateCandidate {
  const TransactionDuplicateCandidate(
    this.transaction, {
    required this.accountMatches,
  }) : super(confidence: DuplicateConfidence.possible);

  final Transaction transaction;

  /// Whether the transaction's account is the one the capture suggests. Only
  /// raises how the UI ranks the candidate; a mismatch never rules it out,
  /// since the account is itself a guess (HU-03).
  final bool accountMatches;

  @override
  List<Object?> get props => [confidence, transaction, accountMatches];
}

/// Another pending capture that describes the same movement: either the same
/// issuer notifying twice (authorization + settlement) or the wallet/bank
/// pair of a single payment.
final class CaptureDuplicateCandidate extends DuplicateCandidate {
  const CaptureDuplicateCandidate(
    this.capture, {
    required this.sameIssuer,
    required super.confidence,
  });

  final PendingCapture capture;

  /// `false` for the wallet + bank pairing, whose grouping deliberately does
  /// NOT require the `sourcePackage` to match.
  final bool sameIssuer;

  @override
  List<Object?> get props => [confidence, capture, sameIssuer];
}
