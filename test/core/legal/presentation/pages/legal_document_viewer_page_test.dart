import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/usecases/resolve_legal_document.dart';
import 'package:billetudo/core/legal/presentation/pages/legal_document_viewer_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../features/auth/presentation/widgets/pump_widget.dart';

class MockResolveLegalDocument extends Mock implements ResolveLegalDocument {}

void main() {
  setUpAll(() => registerFallbackValue(LegalDocumentKind.privacyPolicy));

  tearDown(getIt.reset);

  testWidgets(
      'muestra el titulo, la version/fecha del documento mostrado y sus '
      'secciones, sin loading/error/empty', (tester) async {
    final resolveLegalDocument = MockResolveLegalDocument();
    when(() => resolveLegalDocument(kind: LegalDocumentKind.termsOfUse))
        .thenAnswer(
      (_) async => Right(
        LegalDocument(
          kind: LegalDocumentKind.termsOfUse,
          content: '# Términos de uso\n\n'
              'Intro del documento.\n\n'
              '## Índice\n\n1. [Uno](#1)\n\n'
              '## 1. Primera sección\n\n'
              'Cuerpo de la primera sección con **negrita**.',
          legalVersion: 3,
          effectiveDate: DateTime.utc(2026, 8, 15),
          source: LegalDocumentSource.bundle,
        ),
      ),
    );
    getIt.registerFactory<ResolveLegalDocument>(() => resolveLegalDocument);

    await tester.pumpAuthWidget(
      const LegalDocumentViewerPage(kind: LegalDocumentKind.termsOfUse),
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Términos de uso'), findsOneWidget);
    expect(find.textContaining('Versión 3'), findsOneWidget);
    expect(find.textContaining('15 de agosto de 2026'), findsOneWidget);
    // The intro paragraph (no heading) renders.
    expect(find.text('Intro del documento.'), findsOneWidget);
    // "Índice" is dropped — it is a list of anchors with no destination.
    expect(find.text('Índice'), findsNothing);
    // The real section renders with its heading and stripped markdown.
    expect(find.text('1. Primera sección'), findsOneWidget);
    expect(
      find.text('Cuerpo de la primera sección con negrita.'),
      findsOneWidget,
    );
  });
}
