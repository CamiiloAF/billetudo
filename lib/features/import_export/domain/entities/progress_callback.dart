/// Reports rows (or tables) processed during a long export/import/backup
/// write (HU-01/03/05/09 of `docs/requirements/fase-1/11-import-export.md`).
///
/// [total] is `null` when it is not known ahead of the write — e.g.
/// `commitImport`, which never runs a separate `COUNT` pass before
/// committing, so the caller only ever sees rows-so-far.
typedef ProgressCallback = void Function(int processed, int? total);
