import 'package:equatable/equatable.dart';

import '../../domain/entities/legal_document.dart';

enum LegalReacceptanceStatus {
  /// Nothing to show — either not checked yet, or checked and the
  /// installation is already up to date.
  idle,

  /// The sheet is up, step 1 (list of changed documents + "Acepto").
  step1,

  /// The sheet is up, step 2 ("No acepto"'s consequence + export).
  step2,

  accepting,
}

/// State of `LegalReacceptanceCubit`.
class LegalReacceptanceState extends Equatable {
  const LegalReacceptanceState({
    this.status = LegalReacceptanceStatus.idle,
    this.changedDocuments = const [],
  });

  final LegalReacceptanceStatus status;

  /// Only the documents whose content changed since the version this
  /// installation last accepted — never the unchanged one
  /// (`docs/legal/entrega-de-documentos-legales.md`).
  final List<LegalDocument> changedDocuments;

  bool get isVisible =>
      status == LegalReacceptanceStatus.step1 ||
      status == LegalReacceptanceStatus.step2 ||
      status == LegalReacceptanceStatus.accepting;

  LegalReacceptanceState copyWith({
    LegalReacceptanceStatus? status,
    List<LegalDocument>? changedDocuments,
  }) =>
      LegalReacceptanceState(
        status: status ?? this.status,
        changedDocuments: changedDocuments ?? this.changedDocuments,
      );

  @override
  List<Object?> get props => [status, changedDocuments];
}
