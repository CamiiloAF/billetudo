import 'package:equatable/equatable.dart';

import '../../domain/entities/legal_document.dart';

enum LegalAcceptanceStatus {
  loading,
  ready,
  accepting,
  accepted,
  error,
}

/// State of `LegalAcceptanceCubit`, the just-in-time sheet shown before
/// "Comenzar"/"Ya tengo cuenta" continue (Pencil `TxoKJ`).
class LegalAcceptanceState extends Equatable {
  const LegalAcceptanceState({
    this.status = LegalAcceptanceStatus.loading,
    this.documents = const [],
    this.alreadyAccepted = false,
  });

  final LegalAcceptanceStatus status;

  /// Both documents, resolved from cache/bundle — what is actually about to
  /// be shown and, on "Acepto", actually accepted.
  final List<LegalDocument> documents;

  /// Whether this installation already accepted the manifest's current
  /// version: when `true`, the sheet must not be shown at all (`TxoKJ`'s
  /// context: "si ya fue aceptado, la hoja no vuelve a subir por ninguna de
  /// las dos rutas").
  final bool alreadyAccepted;

  LegalAcceptanceState copyWith({
    LegalAcceptanceStatus? status,
    List<LegalDocument>? documents,
    bool? alreadyAccepted,
  }) =>
      LegalAcceptanceState(
        status: status ?? this.status,
        documents: documents ?? this.documents,
        alreadyAccepted: alreadyAccepted ?? this.alreadyAccepted,
      );

  @override
  List<Object?> get props => [status, documents, alreadyAccepted];
}
