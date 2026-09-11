import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/domain/usecases/resolve_legal_document.dart';
import 'package:billetudo/core/legal/presentation/pages/legal_document_viewer_page.dart';
import 'package:billetudo/core/legal/presentation/widgets/legal_footer_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../features/auth/presentation/widgets/pump_widget.dart';

class MockResolveLegalDocument extends Mock implements ResolveLegalDocument {}

void main() {
  setUpAll(() => registerFallbackValue(LegalDocumentKind.privacyPolicy));

  setUp(() {
    final resolveLegalDocument = MockResolveLegalDocument();
    when(() => resolveLegalDocument(kind: any(named: 'kind'))).thenAnswer(
      (invocation) async => Right(
        LegalDocument(
          kind: invocation.namedArguments[#kind] as LegalDocumentKind,
          content: '# T\n\n## Uno\n\nCuerpo.',
          legalVersion: 1,
          effectiveDate: DateTime.utc(2026, 1, 1),
          source: LegalDocumentSource.bundle,
        ),
      ),
    );
    getIt.registerFactory<ResolveLegalDocument>(() => resolveLegalDocument);
  });

  tearDown(getIt.reset);

  testWidgets(
      'muestra los dos enlaces y cada uno abre el visor nativo del '
      'documento correspondiente, sin alterar el resto de la pantalla',
      (tester) async {
    await tester.pumpAuthWidget(const LegalFooterLinks());

    expect(find.text('Términos de uso'), findsOneWidget);
    expect(find.text('Política de privacidad'), findsOneWidget);

    await tester.tap(find.text('Términos de uso'));
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentViewerPage), findsOneWidget);
  });
}
