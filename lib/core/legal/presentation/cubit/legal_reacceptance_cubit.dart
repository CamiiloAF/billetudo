import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/entities/legal_document.dart';
import '../../domain/repositories/legal_documents_repository.dart';
import '../../domain/usecases/accept_legal_documents.dart';
import '../../domain/usecases/get_changed_legal_documents.dart';
import '../../domain/usecases/get_legal_manifest.dart';
import '../../domain/usecases/resolve_legal_document.dart';
import '../../domain/usecases/should_show_reacceptance.dart';
import 'legal_reacceptance_state.dart';

/// Evaluates [ShouldShowReacceptance] once per app launch and drives the
/// two-step re-acceptance sheet (Pencil `JHwhG`/`X2781z` step 1, `f8KnrT`
/// step 2).
///
/// `@lazySingleton`: the same instance backs every check across the app's
/// lifetime, so [checkOnLaunch] only ever runs its real logic once — later
/// calls (e.g. a rebuild of the widget that triggers it) are no-ops, exactly
/// like the "gate se evalúa una sola vez por arranque" rule `13-onboarding.md`
/// documents for the welcome flow's own gate.
@lazySingleton
class LegalReacceptanceCubit extends Cubit<LegalReacceptanceState> {
  LegalReacceptanceCubit(
    this._getLegalManifest,
    this._repository,
    this._shouldShowReacceptance,
    this._getChangedLegalDocuments,
    this._resolveLegalDocument,
    this._acceptLegalDocuments,
  ) : super(const LegalReacceptanceState());

  final GetLegalManifest _getLegalManifest;
  final LegalDocumentsRepository _repository;
  final ShouldShowReacceptance _shouldShowReacceptance;
  final GetChangedLegalDocuments _getChangedLegalDocuments;
  final ResolveLegalDocument _resolveLegalDocument;
  final AcceptLegalDocuments _acceptLegalDocuments;

  bool _hasChecked = false;

  Future<void> checkOnLaunch() async {
    if (_hasChecked) {
      return;
    }
    _hasChecked = true;

    final manifestResult = await _getLegalManifest();
    final manifest = manifestResult.fold((_) => null, (m) => m);
    if (manifest == null) {
      return;
    }
    final acceptedVersionResult = await _repository.getAcceptedVersion();
    final acceptedVersion = acceptedVersionResult.fold((_) => 0, (v) => v);

    String installedAppVersion;
    try {
      installedAppVersion = (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      // Cannot compare against `minAppVersion` safely — skip this launch's
      // check rather than risk asking for re-acceptance of functionality
      // this install may not have.
      return;
    }

    final shouldShow = _shouldShowReacceptance(
      acceptedVersion: acceptedVersion,
      manifest: manifest,
      installedAppVersion: installedAppVersion,
    );
    if (!shouldShow) {
      return;
    }

    final changed = _getChangedLegalDocuments(
      acceptedVersion: acceptedVersion,
      manifest: manifest,
    );
    if (changed.isEmpty) {
      return;
    }

    final resolvedDocuments = <LegalDocument>[];
    for (final manifestDocument in changed) {
      final result = await _resolveLegalDocument(kind: manifestDocument.kind);
      final document = result.fold((_) => null, (d) => d);
      if (document != null) {
        resolvedDocuments.add(document);
      }
    }
    if (resolvedDocuments.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        status: LegalReacceptanceStatus.step1,
        changedDocuments: resolvedDocuments,
      ),
    );
  }

  void goToDeclineConsequence() =>
      emit(state.copyWith(status: LegalReacceptanceStatus.step2));

  void backToStep1() =>
      emit(state.copyWith(status: LegalReacceptanceStatus.step1));

  Future<bool> accept() async {
    emit(state.copyWith(status: LegalReacceptanceStatus.accepting));
    final result =
        await _acceptLegalDocuments(shownDocuments: state.changedDocuments);
    return result.fold(
      (_) {
        emit(state.copyWith(status: LegalReacceptanceStatus.step1));
        return false;
      },
      (_) {
        emit(const LegalReacceptanceState());
        return true;
      },
    );
  }
}
