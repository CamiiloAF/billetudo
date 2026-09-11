import 'package:flutter/material.dart';

import '../../../../core/widgets/settings_field.dart';

/// A `SettingsField` row that opens a legal document in the native in-app
/// viewer (`LegalDocumentViewerPage`) — never an external browser (Apple +
/// Google both require the privacy policy and terms of use to be reachable
/// from inside the app, and an in-app viewer satisfies that without a
/// network round-trip that could fail).
class LegalLinkField extends StatelessWidget {
  const LegalLinkField({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SettingsField(
        icon: icon,
        label: label,
        sublabel: sublabel,
        onTap: onTap,
      );
}
