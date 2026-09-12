import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/legal_document.dart';
import '../../domain/entities/legal_document_kind.dart';
import '../../domain/repositories/legal_documents_repository.dart';
import '../../domain/usecases/accept_legal_documents.dart';
import '../../domain/usecases/get_legal_manifest.dart';
import '../../domain/usecases/resolve_legal_document.dart';
import 'legal_acceptance_state.dart';

/// Orchestrates the just-in-time acceptance sheet shared by "Comenzar" and
/// "Ya tengo cuenta" (Pencil `TxoKJ`): resolves both documents, decides
/// whether the sheet even needs to be shown, and records joint acceptance.
///
/// One instance per sheet opening (`@injectable`, not a singleton): nothing
/// here needs to survive past the sheet closing.
@injectable
class LegalAcceptanceCubit extends Cubit<LegalAcceptanceState> {
  LegalAcceptanceCubit(
    this._resolveLegalDocument,
    this._acceptLegalDocuments,
    this._getLegalManifest,
    this._repository,
  ) : super(const LegalAcceptanceState());

  final ResolveLegalDocument _resolveLegalDocument;
  final AcceptLegalDocuments _acceptLegalDocuments;
  final GetLegalManifest _getLegalManifest;
  final LegalDocumentsRepository _repository;

  /// Resolves both documents and whether this installation already accepted
  /// the manifest's current version.
  Future<void> load() async {
    final manifestResult = await _getLegalManifest();
    final acceptedVersionResult = await _repository.getAcceptedVersion();
    final currentVersion =
        manifestResult.fold((_) => 0, (m) => m.currentVersion);
    final acceptedVersion = acceptedVersionResult.fold((_) => 0, (v) => v);

    if (acceptedVersion >= currentVersion && currentVersion > 0) {
      emit(state.copyWith(
          alreadyAccepted: true, status: LegalAcceptanceStatus.ready));
      return;
    }

    final documents = <LegalDocument>[];
    for (final kind in LegalDocumentKind.values) {
      final result = await _resolveLegalDocument(kind: kind);
      final document = result.fold((_) => null, (d) => d);
      if (document != null) {
        documents.add(document);
      }
    }
    emit(
      state.copyWith(
        status: LegalAcceptanceStatus.ready,
        documents: documents,
      ),
    );
  }

  /// Registers joint acceptance ("Acepto") with the version(s) actually
  /// shown by [load].
  Future<bool> accept() async {
    emit(state.copyWith(status: LegalAcceptanceStatus.accepting));
    final result = await _acceptLegalDocuments(shownDocuments: state.documents);
    return result.fold(
      (_) {
        emit(state.copyWith(status: LegalAcceptanceStatus.error));
        return false;
      },
      (_) {
        emit(state.copyWith(status: LegalAcceptanceStatus.accepted));
        return true;
      },
    );
  }
}
