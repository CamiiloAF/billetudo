import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/widgets/home_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'pump_widget.dart';

void main() {
  const user = AuthUser(
    id: 'u-1',
    displayName: 'Camila',
    provider: AuthProvider.google,
  );

  Widget header({
    AuthUser? user,
    HomeSyncStatus syncStatus = HomeSyncStatus.synced,
    VoidCallback? onBellTap,
    VoidCallback? onAvatarTap,
    VoidCallback? onWalletTap,
  }) =>
      HomeHeader(
        syncStatus: syncStatus,
        user: user,
        onBellTap: onBellTap ?? () {},
        onAvatarTap: onAvatarTap ?? () {},
        onWalletTap: onWalletTap ?? () {},
      );

  testWidgets('sin sesión: saludo genérico y avatar con ícono (HU-07)',
      (tester) async {
    await tester.pumpHomeWidget(header());

    expect(find.text('Hola de nuevo 👋'), findsOneWidget);
    expect(find.byIcon(LucideIcons.user), findsOneWidget);
  });

  testWidgets('con sesión: saludo con nombre y avatar con inicial (HU-07)',
      (tester) async {
    await tester.pumpHomeWidget(header(user: user));

    expect(find.text('Hola, Camila 👋'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.byIcon(LucideIcons.user), findsNothing);
  });

  testWidgets('en inglés: saludo con nombre localizado (HU-07)',
      (tester) async {
    await tester.pumpHomeWidget(
      header(user: user),
      locale: const Locale('en'),
    );

    expect(find.text('Hi, Camila 👋'), findsOneWidget);
  });

  testWidgets(
      'sin sesión: badge del avatar en estado "sin cuenta" (criterio 1)',
      (tester) async {
    await tester.pumpHomeWidget(header());

    expect(find.byIcon(LucideIcons.cloudUpload), findsOneWidget);
  });

  testWidgets('sincronizado: el badge del avatar no dibuja nada extra',
      (tester) async {
    await tester.pumpHomeWidget(
      header(user: user, syncStatus: HomeSyncStatus.synced),
    );

    expect(find.byIcon(LucideIcons.cloudCheck), findsNothing);
    expect(find.byIcon(LucideIcons.cloudOff), findsNothing);
    expect(find.byIcon(LucideIcons.refreshCw), findsNothing);
  });

  testWidgets('requiere atención: badge ámbar con cloud-off (criterio 1)',
      (tester) async {
    await tester.pumpHomeWidget(
      header(user: user, syncStatus: HomeSyncStatus.attention),
    );

    expect(find.byIcon(LucideIcons.cloudOff), findsOneWidget);
  });

  testWidgets('sincronizando: badge con refresh-cw', (tester) async {
    await tester.pumpHomeWidget(
      header(user: user, syncStatus: HomeSyncStatus.syncing),
    );

    expect(find.byIcon(LucideIcons.refreshCw), findsOneWidget);
  });

  testWidgets('tocar el avatar dispara onAvatarTap', (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      header(user: user, onAvatarTap: () => tapped++),
    );

    await tester.tap(find.text('C'));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tocar el botón wallet dispara onWalletTap', (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      header(user: user, onWalletTap: () => tapped++),
    );

    await tester.tap(find.byIcon(LucideIcons.wallet));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tocar la campana dispara onBellTap', (tester) async {
    var tapped = 0;
    await tester.pumpHomeWidget(
      header(user: user, onBellTap: () => tapped++),
    );

    await tester.tap(find.byIcon(LucideIcons.bell));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tema oscuro: renderiza con tokens oscuros sin excepción (HU-11)',
      (tester) async {
    await tester.pumpHomeWidget(
      header(user: user),
      brightness: Brightness.dark,
    );

    expect(find.text('Hola, Camila 👋'), findsOneWidget);
    final colors = tester.element(find.byType(HomeHeader)).colors;
    final initial = tester.widget<Text>(find.text('C'));
    expect(initial.style!.color, colors.onPrimary);
  });
}
