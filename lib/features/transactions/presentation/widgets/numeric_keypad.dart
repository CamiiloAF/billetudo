import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The anchored numeric keypad of HU-01/02/03 criterion 11.
///
/// Purely a dumb input widget: it only reports which digit or which action
/// was tapped. Whether it is even shown is entirely up to the caller (see
/// `TransactionFormState.isKeypadVisible`), which is what keeps it and the
/// Nota field from ever being on screen with focus at the same time.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onDone,
    super.key,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onDone;

  static const String _doneKey = '✓';

  static const List<String> _keys = [
    '1', '2', '3', //
    '4', '5', '6', //
    '7', '8', '9', //
    _doneKey, '0', '⌫',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          childAspectRatio: 2,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final key in _keys)
              KeypadKey(label: key, onTap: () => _tap(key)),
          ],
        ),
      ),
    );
  }

  void _tap(String key) {
    switch (key) {
      case '⌫':
        onBackspace();
      case _doneKey:
        onDone();
      default:
        onDigit(int.parse(key));
    }
  }
}

class KeypadKey extends StatelessWidget {
  const KeypadKey({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
