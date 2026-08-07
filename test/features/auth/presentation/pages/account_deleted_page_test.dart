import 'package:billetudo/features/auth/domain/entities/delete_account_scope.dart';
import 'package:billetudo/features/auth/presentation/pages/account_deleted_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/pump_widget.dart';

void main() {
  testWidgets(
      'HU-07 paso 3 (cloudAndLocal): cierre neutral que solo habla de la '
      'nube, nunca de los datos locales', (tester) async {
    await tester.pumpAuthWidget(
      AccountDeletedPage(
        scope: DeleteAccountScope.cloudAndLocal,
        onGoHome: () {},
      ),
      wrapInScaffold: false,
    );

    expect(find.text('Listo, tu cuenta fue eliminada'), findsOneWidget);
    expect(
      find.text(
        'Ya no tenemos ningún dato tuyo en la nube. Puedes seguir usando '
        'billetudo cuando quieras, con o sin cuenta.',
      ),
      findsOneWidget,
    );
    // Deliberately says nothing about local data one way or the other.
    expect(find.textContaining('dispositivo'), findsNothing);
    expect(find.byIcon(LucideIcons.check), findsOneWidget);
  });

  testWidgets(
      'HU-07 paso 3 (localOnlySignedOut): NO afirma que la cuenta en la '
      'nube fue eliminada — solo dice que se borró lo local', (tester) async {
    await tester.pumpAuthWidget(
      AccountDeletedPage(
        scope: DeleteAccountScope.localOnlySignedOut,
        onGoHome: () {},
      ),
      wrapInScaffold: false,
    );

    expect(
      find.text('Listo, borramos tus datos de este dispositivo'),
      findsOneWidget,
    );
    expect(
      find.textContaining('tu cuenta en la nube sigue existiendo'),
      findsOneWidget,
    );
    // Must never claim the cloud account was deleted for this scope.
    expect(find.text('Listo, tu cuenta fue eliminada'), findsNothing);
    expect(
      find.textContaining('Ya no tenemos ningún dato tuyo en la nube'),
      findsNothing,
    );
  });

  testWidgets(
      'HU-07 paso 3 (localOnlyNeverSignedIn): copy veraz que no menciona '
      'la nube en absoluto, ni afirma que no queda nada ahí', (tester) async {
    await tester.pumpAuthWidget(
      AccountDeletedPage(
        scope: DeleteAccountScope.localOnlyNeverSignedIn,
        onGoHome: () {},
      ),
      wrapInScaffold: false,
    );

    expect(
      find.text('Listo, borramos tus datos de este dispositivo'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Borramos la información guardada en este dispositivo. Puedes '
        'seguir usando billetudo cuando quieras, con o sin cuenta.',
      ),
      findsOneWidget,
    );
    // Must never claim the cloud account was deleted for this scope —
    // `everSignedIn` is local-only and cannot verify a cloud account
    // doesn't exist (reinstall, second device, sign-in race).
    expect(find.text('Listo, tu cuenta fue eliminada'), findsNothing);
    expect(
      find.textContaining('Ya no tenemos ningún dato tuyo en la nube'),
      findsNothing,
    );
    expect(find.textContaining('nube'), findsNothing);
  });

  testWidgets('el CTA "Ir al inicio" dispara onGoHome', (tester) async {
    var wentHome = false;
    await tester.pumpAuthWidget(
      AccountDeletedPage(
        scope: DeleteAccountScope.cloudAndLocal,
        onGoHome: () => wentHome = true,
      ),
      wrapInScaffold: false,
    );

    await tester.tap(find.text('Ir al inicio'));
    await tester.pump();

    expect(wentHome, isTrue);
  });
}
