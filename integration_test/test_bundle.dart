// GENERATED CODE - DO NOT MODIFY BY HAND AND DO NOT COMMIT TO VERSION CONTROL
// ignore_for_file: type=lint, invalid_use_of_internal_member

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol/src/platform/contracts/contracts.dart';
import 'package:test_api/src/backend/invoker.dart';

// START: GENERATED TEST IMPORTS
import 'accounts_patrol_test.dart' as accounts_patrol_test;
import 'auth_patrol_test.dart' as auth_patrol_test;
import 'budget_income_counts_in_budget_patrol_test.dart' as budget_income_counts_in_budget_patrol_test;
import 'budgets_patrol_test.dart' as budgets_patrol_test;
import 'categories_patrol_test.dart' as categories_patrol_test;
import 'debts_installment_patrol_test.dart' as debts_installment_patrol_test;
import 'debts_lifecycle_patrol_test.dart' as debts_lifecycle_patrol_test;
import 'debts_patrol_test.dart' as debts_patrol_test;
import 'goals_patrol_test.dart' as goals_patrol_test;
import 'home_patrol_test.dart' as home_patrol_test;
import 'onboarding_patrol_test.dart' as onboarding_patrol_test;
import 'reports_patrol_test.dart' as reports_patrol_test;
import 'scheduled_payments_patrol_test.dart' as scheduled_payments_patrol_test;
import 'settings_patrol_test.dart' as settings_patrol_test;
import 'transactions_patrol_test.dart' as transactions_patrol_test;
// END: GENERATED TEST IMPORTS

Future<void> main() async {
  // This is the entrypoint of the bundled Dart test.
  //
  // Its responsibilities are:
  //  * Running a special Dart test that runs before all the other tests and
  //    explores the hierarchy of groups and tests.
  //  * Hosting a PatrolAppService, which the native side of Patrol uses to get
  //    the Dart tests, and to request execution of a specific Dart test.
  //
  // When running on Android, the Android Test Orchestrator, before running the
  // tests, makes an initial run to gather the tests that it will later run. The
  // native side of Patrol (specifically: PatrolJUnitRunner class) is hooked
  // into the Android Test Orchestrator lifecycle and knows when that initial
  // run happens. When it does, PatrolJUnitRunner makes an RPC call to
  // PatrolAppService and asks it for Dart tests.
  //
  // When running on iOS, the native side of Patrol (specifically: the
  // PATROL_INTEGRATION_TEST_IOS_RUNNER macro) makes an initial run to gather
  // the tests that it will later run (same as the Android). During that initial
  // run, it makes an RPC call to PatrolAppService and asks it for Dart tests.
  //
  // Once the native runner has the list of Dart tests, it dynamically creates
  // native test cases from them. On Android, this is done using the
  // Parametrized JUnit runner. On iOS, new test case methods are swizzled into
  // the RunnerUITests class, taking advantage of the very dynamic nature of
  // Objective-C runtime.
  //
  // Execution of these dynamically created native test cases is then fully
  // managed by the underlying native test framework (JUnit on Android, XCTest
  // on iOS). The native test cases do only one thing - request execution of the
  // Dart test (out of which they had been created) and wait for it to complete.
  // The result of running the Dart test is the result of the native test case.

  final platformAutomator = PlatformAutomator(
    config: PlatformAutomatorConfig.defaultConfig(),
  );
  await platformAutomator.initialize();
  final binding = PatrolBinding.ensureInitialized(platformAutomator);
  final testExplorationCompleter = Completer<DartGroupEntry>();

  // A special test to explore the hierarchy of groups and tests. This is a hack
  // around https://github.com/dart-lang/test/issues/1998.
  //
  // This test must be the first to run. If not, the native side likely won't
  // receive any tests, and everything will fall apart.
  test('patrol_test_explorer', () {
    // Maybe somewhat counterintuitively, this callback runs *after* the calls
    // to group() below.
    final topLevelGroup = Invoker.current!.liveTest.groups.first;
    final dartTestGroup = createDartTestGroup(
      topLevelGroup,
      tags: null,
      excludeTags: null,
    );
    testExplorationCompleter.complete(dartTestGroup);
    print('patrol_test_explorer: obtained Dart-side test hierarchy:');
    reportGroupStructure(dartTestGroup);
  });

// START: GENERATED TEST GROUPS
  group('accounts_patrol_test', accounts_patrol_test.main);
  group('auth_patrol_test', auth_patrol_test.main);
  group('budget_income_counts_in_budget_patrol_test', budget_income_counts_in_budget_patrol_test.main);
  group('budgets_patrol_test', budgets_patrol_test.main);
  group('categories_patrol_test', categories_patrol_test.main);
  group('debts_installment_patrol_test', debts_installment_patrol_test.main);
  group('debts_lifecycle_patrol_test', debts_lifecycle_patrol_test.main);
  group('debts_patrol_test', debts_patrol_test.main);
  group('goals_patrol_test', goals_patrol_test.main);
  group('home_patrol_test', home_patrol_test.main);
  group('onboarding_patrol_test', onboarding_patrol_test.main);
  group('reports_patrol_test', reports_patrol_test.main);
  group('scheduled_payments_patrol_test', scheduled_payments_patrol_test.main);
  group('settings_patrol_test', settings_patrol_test.main);
  group('transactions_patrol_test', transactions_patrol_test.main);
// END: GENERATED TEST GROUPS

  final dartTestGroup = await testExplorationCompleter.future;
  final appService = PatrolAppService(topLevelDartTestGroup: dartTestGroup);
  binding.patrolAppService = appService;
  await runAppService(appService);

  // Until now, the native test runner was waiting for us, the Dart side, to
  // come alive. Now that we did, let's tell it that we're ready to be asked
  // about Dart tests.
  await platformAutomator.markPatrolAppServiceReady();

  await appService.testExecutionCompleted;
}
