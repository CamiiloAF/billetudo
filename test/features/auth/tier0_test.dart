import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nivel 0: el respaldo/sync en sí es gratis desde el día 1 — no es una
/// feature de monetización (`docs/requirements/05-auth-sync.md`). Solo
/// IA/gráficas avanzadas (features futuras, ajenas a esta) se monetizan.
/// Además, HU-01 exige que ninguna pantalla de login bloquee el acceso a
/// features de Nivel 0: el login es siempre una invitación posterior, nunca
/// un requisito de entrada.
///
/// Se verifica sobre el código fuente (igual que el patrón de
/// `test/features/accounts/tier0_test.dart`) porque es una regla de
/// producto: un test de comportamiento no puede probar la *ausencia* de un
/// paywall que nadie escribió todavía, pero sí puede fallar el día que
/// alguien lo agregue.
void main() {
  final authDir = Directory('lib/features/auth');
  final settingsDir = Directory('lib/features/settings');

  List<File> dartFilesOf(Directory dir) => dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  setUpAll(() {
    expect(authDir.existsSync(), isTrue,
        reason: 'No se encontró lib/features/auth');
    expect(settingsDir.existsSync(), isTrue,
        reason: 'No se encontró lib/features/settings');
    expect(dartFilesOf(authDir), isNotEmpty);
    expect(dartFilesOf(settingsDir), isNotEmpty);
  });

  test('Auth y Ajustes no importan monetización (ads, RevenueCat, paywall)',
      () {
    const forbidden = [
      'google_mobile_ads',
      'revenuecat',
      'purchases_flutter',
      'admob',
      'in_app_purchase',
    ];

    final offenders = <String>[];
    for (final file in [...dartFilesOf(authDir), ...dartFilesOf(settingsDir)]) {
      final source = file.readAsStringSync().toLowerCase();
      for (final import in forbidden) {
        if (source.contains(import)) {
          offenders.add('${file.path} -> $import');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Nivel 0: respaldo/sync no puede depender de monetización.\n'
          '${offenders.join('\n')}',
    );
  });

  test('ninguna capacidad de Auth/Ajustes está condicionada por premium o cupo',
      () {
    final gatePattern = RegExp(
      r'\b(isPremium|isPro|hasPremium|requiresPremium|premiumOnly|'
      r'showPaywall|paywall|entitlement|rewardedAd|showRewarded|'
      r'hasQuota|quotaLeft|remainingQuota|checkQuota|consumeQuota|'
      r'isLocked|unlockWithAd)\b',
    );

    final offenders = <String>[];
    for (final file in [...dartFilesOf(authDir), ...dartFilesOf(settingsDir)]) {
      for (final (index, line) in file.readAsLinesSync().indexed) {
        if (gatePattern.hasMatch(line)) {
          offenders.add('${file.path}:${index + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Nivel 0: ninguna capacidad de respaldo/sync va detrás de pago/cupo.\n'
          '${offenders.join('\n')}',
    );
  });

  test(
      'HU-01: las rutas de Nivel 0 (cuentas, movimientos, categorías) no '
      'dependen de la sesión de auth', () {
    // AppRouter is the single source of truth for which routes exist and how
    // they're built. Tier 0 destinations must never gate their `builder` on
    // an `AuthSession`/`AuthCubit` check (e.g. `if (session.isSignedIn)`
    // deciding whether to render the page at all) — only Ajustes/Más are
    // allowed to *branch their own content* on session state (to show/hide
    // "Cerrar sesión" or the session card), never to block navigation.
    final routerSource =
        File('lib/core/router/app_router.dart').readAsStringSync();

    // Crude but effective: no route builder for /cuentas, /movimientos or
    // /categorias may reference AuthSession/AuthCubit/isSignedIn at all.
    for (final routeConst in ['accounts', 'transactions', 'categories']) {
      final routeMatch = RegExp(
        'GoRoute\\s*\\(\\s*path:\\s*AppRoutes\\.$routeConst,'
        r'[\s\S]*?builder:\s*\(context, state\)\s*=>([\s\S]*?)\n\s*\),',
      ).firstMatch(routerSource);
      expect(
        routeMatch,
        isNotNull,
        reason: 'No se encontró la ruta $routeConst en app_router.dart',
      );
      final builderBody = routeMatch!.group(1)!;
      expect(
        builderBody,
        isNot(
          anyOf(
            contains('AuthSession'),
            contains('AuthCubit'),
            contains('isSignedIn'),
          ),
        ),
        reason:
            'HU-01: la ruta $routeConst no puede depender de la sesión de auth\n'
            '$builderBody',
      );
    }
  });

  test('la app arranca en Inicio (`/`), nunca en una pantalla de login', () {
    final routerSource =
        File('lib/core/router/app_router.dart').readAsStringSync();
    expect(
      routerSource,
      contains('initialLocation: AppRoutes.home'),
      reason: 'HU-01: local-first estricto — el login nunca es un gate de '
          'entrada, la app debe abrir directo en Inicio.',
    );
  });

  test('DeleteAccount y SignOut no dependen de monetización', () {
    for (final path in [
      'lib/features/auth/domain/usecases/delete_account.dart',
      'lib/features/auth/domain/usecases/sign_out.dart',
    ]) {
      final source = File(path).readAsStringSync();
      final imports = RegExp(r"^import\s+'([^']+)'", multiLine: true)
          .allMatches(source)
          .map((match) => match.group(1)!)
          .toList();

      expect(imports, isNotEmpty);
      for (final import in imports) {
        expect(
          import,
          isNot(
            anyOf(contains('ads'), contains('purchase'), contains('billing')),
          ),
          reason: '$path no puede depender de monetización',
        );
      }
    }
  });
}
