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

  Widget header({AuthUser? user}) => HomeHeader(
        syncStatus: HomeSyncStatus.synced,
        user: user,
        onBellTap: () {},
      );

  testWidgets('sin sesión: saludo genérico y avatar con ícono (HU-07)',
      (tester) async {
    await tester.pumpHomeWidget(header());

    expect(find.text('Hola de nuevo'), findsOneWidget);
    expect(find.byIcon(LucideIcons.user), findsOneWidget);
  });

  testWidgets('con sesión: saludo con nombre y avatar con inicial (HU-07)',
      (tester) async {
    await tester.pumpHomeWidget(header(user: user));

    expect(find.text('Hola de nuevo, Camila'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.byIcon(LucideIcons.user), findsNothing);
  });

  testWidgets('en inglés: saludo con nombre localizado (HU-07)',
      (tester) async {
    await tester.pumpHomeWidget(
      header(user: user),
      locale: const Locale('en'),
    );

    expect(find.text('Welcome back, Camila'), findsOneWidget);
  });

  testWidgets('tema oscuro: renderiza con tokens oscuros sin excepción (HU-11)',
      (tester) async {
    await tester.pumpHomeWidget(
      header(user: user),
      brightness: Brightness.dark,
    );

    expect(find.text('Hola de nuevo, Camila'), findsOneWidget);
    final colors = tester.element(find.byType(HomeHeader)).colors;
    final initial = tester.widget<Text>(find.text('C'));
    expect(initial.style!.color, colors.onPrimary);
  });
}
