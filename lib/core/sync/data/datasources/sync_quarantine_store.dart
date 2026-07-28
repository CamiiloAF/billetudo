import '../../domain/entities/quarantined_operation.dart';

/// Persistence port for the quarantine. Narrow on purpose: the repository
/// owns the rules (when to retry, when to bump attempts), the store only
/// keeps rows alive across restarts.
abstract class SyncQuarantineStore {
  /// Every quarantined operation, oldest first.
  Future<List<QuarantinedOperation>> readAll();

  /// Current contents, then every change.
  Stream<List<QuarantinedOperation>> watchAll();

  /// Inserts or replaces a record by id.
  Future<void> upsert(QuarantinedOperation operation);

  Future<void> remove(String id);

  Future<void> removeAll();
}
