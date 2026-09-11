import 'package:billetudo/core/legal/domain/entities/legal_document.dart';
import 'package:billetudo/core/legal/domain/entities/legal_document_kind.dart';
import 'package:billetudo/core/legal/presentation/cubit/legal_reacceptance_cubit.dart';
import 'package:billetudo/core/legal/presentation/cubit/legal_reacceptance_state.dart';
import 'package:billetudo/core/legal/presentation/widgets/sheets/legal_reacceptance_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../features/auth/presentation/widgets/pump_widget.dart';

class MockLegalReacceptanceCubit extends MockCubit<LegalReacceptanceState>
    implements LegalReacceptanceCubit {}

void main() {
  late MockLegalReacceptanceCubit cubit;

  LegalDocument document(LegalDocumentKind kind) => LegalDocument(
        kind: kind,
        content: 'contenido',
        legalVersion: 2,
        effectiveDate: DateTime.utc(2026, 1, 1),
        source: LegalDocumentSource.bundle,
      );

  void seed(LegalReacceptanceState state) {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, const Stream<LegalReacceptanceState>.empty(),
        initialState: state);
  }

  setUp(() {
    cubit = MockLegalReacceptanceCubit();
  });

  Future<void> pumpSheet(WidgetTester tester) => tester.pumpAuthWidget(
        BlocProvider<LegalReacceptanceCubit>.value(
          value: cubit,
          child: const LegalReacceptanceSheet(),
        ),
      );

  testWidgets(
      'variante con los dos documentos cambiados: lista ambas filas y copy '
      'en plural', (tester) async {
    seed(
      LegalReacceptanceState(
        status: LegalReacceptanceStatus.step1,
        changedDocuments: [
          document(LegalDocumentKind.termsOfUse),
          document(LegalDocumentKind.privacyPolicy),
        ],
      ),
    );

    await pumpSheet(tester);

    expect(
      find.text(
        'Actualizamos los Términos de uso y la Política de privacidad',
      ),
      findsOneWidget,
    );
    expect(find.text('Términos de uso'), findsOneWidget);
    expect(find.text('Política de privacidad'), findsOneWidget);
    expect(find.text('Acepto los términos y la política'), findsOneWidget);
  });

  testWidgets(
      'variante con un solo documento cambiado (política): una sola fila y '
      'copy en singular', (tester) async {
    seed(
      LegalReacceptanceState(
        status: LegalReacceptanceStatus.step1,
        changedDocuments: [document(LegalDocumentKind.privacyPolicy)],
      ),
    );

    await pumpSheet(tester);

    expect(
      find.text('Actualizamos la Política de privacidad'),
      findsOneWidget,
    );
    expect(find.text('Política de privacidad'), findsOneWidget);
    expect(find.text('Términos de uso'), findsNothing);
    expect(find.text('Acepto la nueva política'), findsOneWidget);
  });

  testWidgets('tocar Acepto llama a cubit.accept()', (tester) async {
    seed(
      LegalReacceptanceState(
        status: LegalReacceptanceStatus.step1,
        changedDocuments: [document(LegalDocumentKind.termsOfUse)],
      ),
    );
    when(cubit.accept).thenAnswer((_) async => true);

    await pumpSheet(tester);
    await tester.tap(find.text('Acepto los nuevos términos'));
    await tester.pump();

    verify(cubit.accept).called(1);
  });

  testWidgets('tocar No acepto llama a goToDeclineConsequence', (tester) async {
    seed(
      LegalReacceptanceState(
        status: LegalReacceptanceStatus.step1,
        changedDocuments: [document(LegalDocumentKind.termsOfUse)],
      ),
    );

    await pumpSheet(tester);
    await tester.tap(find.text('No acepto'));

    verify(cubit.goToDeclineConsequence).called(1);
  });

  testWidgets('paso 2: muestra la consecuencia y el boton de exportar',
      (tester) async {
    seed(
      const LegalReacceptanceState(status: LegalReacceptanceStatus.step2),
    );

    await pumpSheet(tester);

    expect(find.text('Sin aceptar no podemos continuar'), findsOneWidget);
    expect(find.text('Exportar mis datos'), findsOneWidget);
    expect(find.text('Volver a los términos'), findsOneWidget);
  });

  testWidgets('paso 2: volver a los terminos llama a backToStep1',
      (tester) async {
    seed(
      const LegalReacceptanceState(status: LegalReacceptanceStatus.step2),
    );

    await pumpSheet(tester);
    await tester.tap(find.text('Volver a los términos'));

    verify(cubit.backToStep1).called(1);
  });
}
