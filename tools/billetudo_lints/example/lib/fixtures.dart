// Regression fixtures for billetudo_lints. Each `expect_lint` comment asserts
// that the rule below it fires; any line without one must stay clean. Run with
// `dart run custom_lint` from this directory.
//
// ignore_for_file: unused_element

import 'package:flutter/material.dart';

// --- avoid_widget_functions -------------------------------------------------

// expect_lint: avoid_widget_functions
Widget buildBadge(String label) => Chip(label: Text(label));

class WidgetFunctionCases extends StatelessWidget {
  const WidgetFunctionCases({super.key});

  // A `build` override is the framework's own contract, not a helper.
  @override
  Widget build(BuildContext context) {
    // A `builder:` closure is an extension point, not a widget function.
    return Builder(builder: (context) => const SizedBox.shrink());
  }

  // expect_lint: avoid_widget_functions
  Widget buildHeader() => const SizedBox.shrink();
}

// Non-widget helpers are none of this rule's business.
String formatLabel(String value) => value.toUpperCase();

// --- avoid_private_widgets --------------------------------------------------

// expect_lint: avoid_private_widgets
class _PrivateCard extends StatelessWidget {
  const _PrivateCard();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// A private State is how the framework itself is written, and is not a Widget.
class PublicCard extends StatefulWidget {
  const PublicCard({super.key});

  @override
  State<PublicCard> createState() => _PublicCardState();
}

class _PublicCardState extends State<PublicCard> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// --- avoid_hardcoded_ui_strings ---------------------------------------------

class StringCases extends StatelessWidget {
  const StringCases({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // expect_lint: avoid_hardcoded_ui_strings
        const Text('Saldo disponible'),
        // expect_lint: avoid_hardcoded_ui_strings
        const Tooltip(message: 'Editar', child: SizedBox.shrink()),
        // An empty string carries no language.
        const Text(''),
        // Asset paths and package names are technical, not user-facing.
        Image.asset('assets/logo.png', package: 'billetudo'),
        // Non-widget constructors are out of scope: this is a locale id.
        Text(DateTime.now().toIso8601String()),
      ],
    );
  }
}

// A technical string outside a widget is fine — nobody reads it but us.
Exception buildFailure() => Exception('account not found');
