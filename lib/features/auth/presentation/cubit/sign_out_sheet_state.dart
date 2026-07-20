import 'package:equatable/equatable.dart';

/// State of the "Cerrar sesión" sheet (HU-06): the opt-in the user is
/// configuring, plus the photo of the upload queue taken when it opened.
class SignOutSheetState extends Equatable {
  const SignOutSheetState({
    this.deleteLocalData = false,
    this.pendingUploadCount = 0,
  });

  /// "Borrar también los datos de este teléfono". Off by default: without an
  /// account the app is still fully usable (local-first), so wiping can never
  /// be the path taken by omission.
  final bool deleteLocalData;

  /// Changes that have not reached the cloud yet. `0` both when the device is
  /// up to date and when the queue could not be read — the warning is only
  /// shown on a count we actually have.
  final int pendingUploadCount;

  /// The amber warning is only relevant once wiping is on the table: with the
  /// opt-in off nothing local is lost, queued or not.
  bool get showsUnsyncedWarning => deleteLocalData && pendingUploadCount > 0;

  SignOutSheetState copyWith({bool? deleteLocalData, int? pendingUploadCount}) =>
      SignOutSheetState(
        deleteLocalData: deleteLocalData ?? this.deleteLocalData,
        pendingUploadCount: pendingUploadCount ?? this.pendingUploadCount,
      );

  @override
  List<Object?> get props => [deleteLocalData, pendingUploadCount];
}
