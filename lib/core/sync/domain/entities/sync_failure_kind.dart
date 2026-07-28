/// How the upload path must react to a failed write.
///
/// The distinction exists because the two wrong answers are both expensive:
/// retrying a write that can never succeed blocks the FIFO upload queue for
/// every table forever (three days of silent data loss on 2026-07-2x, caused
/// by a missing `debts.closed_at` column in Postgres), and dropping a write
/// that would have succeeded on the next attempt loses user data.
enum SyncFailureKind {
  /// Network, timeout, 5xx, expired JWT, anything unrecognised. Retrying is
  /// the right call; the operation stays in the queue.
  transient,

  /// The client is ahead of the cloud schema: a column or table it writes does
  /// not exist there yet (`PGRST204`, `PGRST205`, `42703`, `42P01`). A
  /// deployment bug, not a user problem — retrying can only block the queue,
  /// so the operation is quarantined and reported with high severity.
  brokenSchema,

  /// The cloud rejected the *content* of the write: invalid value, constraint
  /// violation, or RLS denial (`22xxx`, `23xxx`, `42501`). Also unretryable as
  /// is, so it is quarantined for manual retry once the cause is fixed.
  invalidData,

  /// Nobody classified this one: the backend kept answering with something we
  /// do not recognise, for long enough that letting it keep the FIFO queue
  /// hostage became the bigger risk. The retry watchdog — not a verdict on the
  /// write itself — took it out of the queue.
  ///
  /// This is the residual case the classifier cannot cover by name, and the
  /// one that caused the three-day blockage. A record with this kind means
  /// "a failure mode we had not foreseen showed up"; it is worth investigating
  /// and it is always retryable by hand once the cause is understood.
  stuck;

  /// Whether the upload queue should keep this operation and try again.
  bool get isTransient => this == SyncFailureKind.transient;

  /// Whether the operation must leave the queue and go to the quarantine.
  bool get isPermanent => !isTransient;
}
