// Patrol e2e for Onboarding (feature 13, HU-01/HU-02/HU-04/HU-06/HU-07).
// Runs the real app — real DI graph, real on-device Drift database, real
// go_router navigation — against a real emulator/simulator. No datasource or
// repository is mocked.
//
// Unlike every other suite in this directory, these scenarios do not call
// `startApp`: that helper always mounts `BilletudoApp()` with its default
// `initialLocation` (`AppRoutes.home`), so it never actually renders
// `WelcomePage` — see `support/patrol_app.dart`'s `startOnboardingApp` doc
// comment. `startOnboardingApp` pins `initialLocation: AppRoutes.onboarding`
// instead, reproducing the route a real fresh install's `bootstrap.dart`
// would have chosen against this same clean database.
//
// Two of `13-onboarding.md`'s three e2e paths are covered here:
//   (a) first launch, creating the pre-filled account -> registering the
//       first movement -> Home.
//   (b) first launch, skipping the account -> Home.
// The third — "Ya tengo cuenta" -> login -> onboarding cerrado (HU-06) —
// cannot be automated in this environment: it requires a real Google/Apple
// OAuth round-trip through the native SDK's interactive consent screen, and
// no test Google account is configured on this emulator. This is the same
// constraint `auth_patrol_test.dart`'s own file comment documents for HU-01's
// login screen (its "Supabase/PowerSync are not wired into this project yet"
// framing is stale now that both are wired — see `AuthRepositoryImpl` — but
// the underlying blocker, an interactive native sign-in sheet Patrol cannot
// drive or fake, still applies). `OnboardingFlowCubit.authenticated()` and
// `_finishOnboardingAfterLogin`'s `closesFlow` branch already have full
// coverage without a real backend at the unit level
// (`test/features/onboarding/presentation/cubit/onboarding_flow_cubit_test.dart`).
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/features/home/presentation/pages/home_page.dart';
import 'package:billetudo/features/onboarding/presentation/pages/backup_intro_page.dart';
import 'package:billetudo/features/onboarding/presentation/pages/closing_page.dart';
import 'package:billetudo/features/onboarding/presentation/pages/first_account_page.dart';
import 'package:billetudo/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Creates one expense category ("Comida") from `/categorias`, the same flow
/// `transactions_patrol_test.dart`'s own `_createCategory` uses. Needed
/// because `startOnboardingApp` — like every helper in this harness — skips
/// `bootstrap.dart`, so the seed catalog (HU-03: "ya está sembrado cuando el
/// usuario llega al onboarding") never actually runs here; a real device
/// always has it by the time HU-04's transaction form opens.
Future<void> _createCategoryForTransaction(PatrolIntegrationTester $) async {
  // A fresh `context` before every `go()`: each one collapses/rebuilds the
  // whole page stack (see `transactions_patrol_test.dart`'s own
  // `_goToTransactions` doc comment on `go` vs `push`), which deactivates
  // whatever `Scaffold` element the previous `context` pointed at — reusing
  // it for the second `go()` below hits `Element._debugCheckStateIsActive-
  // ForAncestorLookup`'s "deactivated widget" assertion, verified against a
  // real emulator run.
  GoRouter.of($.tester.element(find.byType(Scaffold).first))
      .go(AppRoutes.categories);
  await $.tester.pumpAndSettle();

  await $.tester.tap(find.byTooltip('Crear categoría'));
  await $.tester.pumpAndSettle();
  await $.tester.enterText(find.byType(TextFormField), 'Comida');
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byIcon(LucideIcons.check));
  await $.tester.pumpAndSettle();

  GoRouter.of($.tester.element(find.byType(Scaffold).first))
      .go(AppRoutes.onboarding);
  await $.tester.pumpAndSettle();
}

void main() {
  patrolTest(
    'HU-01, HU-02, HU-04: primer arranque creando la cuenta pre-llenada '
    'termina registrando el primer movimiento y llega a Inicio',
    ($) async {
      await startOnboardingApp($);
      await _createCategoryForTransaction($);

      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.text('Comenzar'), findsOneWidget);

      await $.tester.tap(find.text('Comenzar'));
      await $.tester.pumpAndSettle();

      // HU-02: the pre-filled draft (Ahorros/savings/COP/$0) is valid on its
      // own — no field needs to be touched before "Crear cuenta".
      expect(find.byType(FirstAccountPage), findsOneWidget);
      expect(find.text('Crear cuenta'), findsOneWidget);
      await $.tester.tap(find.text('Crear cuenta'));
      await $.tester.pumpAndSettle();

      // HU-07: informative screen; "Después" advances without authenticating.
      expect(find.byType(BackupIntroPage), findsOneWidget);
      await $.tester.tap(find.text('Después'));
      await $.tester.pumpAndSettle();

      // HU-04: the account was created (not skipped), so the CTA registers a
      // movement, never the account-bridge copy.
      expect(find.byType(ClosingPage), findsOneWidget);
      expect(find.text('Registra tu primer movimiento'), findsOneWidget);
      await $.tester.tap(find.text('Registra tu primer movimiento'));
      await $.tester.pumpAndSettle();

      expect(find.byType(TransactionFormPage), findsOneWidget);
      await $.tester.tap(find.text('\$0'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('2'));
      await $.tester.tap(find.text('5'));
      await $.tester.tap(find.text('0'));
      await $.tester.pumpAndSettle();
      // Only one category exists ("Comida"), so `GetMostUsedCategories`
      // surfaces it directly as a quick-picker chip — no sheet needed.
      await $.tester.tap(find.text('Comida'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      // The onboarding closed on HU-04's own action (registering here), not
      // on the save — `_finishOnboardingThen` already sent us to Home before
      // the transaction form even opened, so saving/popping lands there too.
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(WelcomePage), findsNothing);
    },
  );

  patrolTest(
    'HU-02, HU-04: primer arranque omitiendo la cuenta llega a Inicio con el '
    'CTA de cierre cambiado a crear cuenta',
    ($) async {
      await startOnboardingApp($);

      await $.tester.tap(find.text('Comenzar'));
      await $.tester.pumpAndSettle();

      expect(find.byType(FirstAccountPage), findsOneWidget);
      expect(find.text('Omitir por ahora'), findsOneWidget);
      await $.tester.tap(find.text('Omitir por ahora'));
      await $.tester.pumpAndSettle();

      expect(find.byType(BackupIntroPage), findsOneWidget);
      await $.tester.tap(find.text('Después'));
      await $.tester.pumpAndSettle();

      // HU-04: the account step was skipped, so the CTA bridges to creating
      // one instead of opening the (accountId-NOT-NULL) transaction form.
      expect(find.byType(ClosingPage), findsOneWidget);
      expect(find.text('Crea tu primera cuenta'), findsOneWidget);
      expect(find.text('Registra tu primer movimiento'), findsNothing);

      // "Lo hago después": skips the CTA entirely, still closing the flow —
      // HU-04's own criterion ("no depende de que haya creado una cuenta").
      await $.tester.tap(find.text('Lo hago después'));
      await $.tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(WelcomePage), findsNothing);
    },
  );
}
