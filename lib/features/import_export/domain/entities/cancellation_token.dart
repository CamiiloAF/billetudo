/// A simple cooperative cancellation flag (HU-01/03/05/09 of
/// `docs/requirements/11-import-export.md`): passed down into a long write so
/// it can check [isCancelled] between rows/tables and stop cleanly, instead
/// of exposing a bare `Future` that cannot be interrupted once it starts.
///
/// One instance per run — a cubit creates a fresh token before starting a
/// write, keeps it to call [cancel] from the "Cancelar" button, and discards
/// it once the write settles.
class CancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() => _isCancelled = true;
}

/// Thrown by a `data/` writer when it observes [CancellationToken.isCancelled]
/// mid-write, so the surrounding `catch` runs the same cleanup path as any
/// other write failure — delete the partial file, or let the enclosing Drift
/// transaction roll back — instead of treating cancellation as a bug.
class OperationCancelledException implements Exception {
  const OperationCancelledException();

  @override
  String toString() => 'OperationCancelledException';
}
