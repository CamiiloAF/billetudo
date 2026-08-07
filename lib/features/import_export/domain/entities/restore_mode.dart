/// How `RestoreBackup` reconciles a copy's content with what already exists
/// locally (HU-04). Chosen explicitly by the user every time — there is no
/// silent default at the repository level.
enum RestoreMode {
  /// Combine by `id`: a row that does not exist is created; a row that does
  /// exist keeps whichever side has the greater `updatedAt` (last-write-wins,
  /// same rule the sync layer uses). Idempotent.
  merge,

  /// Wipes local data and leaves exactly the copy's content. Destructive and
  /// irreversible — gated by an escalated confirmation in `presentation/`.
  replaceAll,
}
