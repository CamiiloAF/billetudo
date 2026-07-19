import 'package:billetudo/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createAppRouter', () {
    test(
      'builds without go_router parentNavigatorKey assertion failures',
      () {
        // `StatefulShellRoute.indexedStack` validates every branch's
        // top-level routes synchronously in its constructor
        // (`_debugValidateParentNavigatorKeys`): a branch-root `GoRoute`
        // can only declare `parentNavigatorKey: null` or its own branch's
        // navigator key. Routes meant to render above the tab bar (Cuentas,
        // Categorías, Pagos Programados) must instead be top-level
        // `GoRouter` routes, siblings of the shell — this smoke test is
        // what actually catches a regression back to declaring them as
        // branch-root routes with `parentNavigatorKey: _rootNavigatorKey`,
        // since that only throws at router-construction time, not in
        // `flutter analyze` or in widget tests that never build the real
        // router.
        expect(createAppRouter, returnsNormally);
      },
    );
  });
}
