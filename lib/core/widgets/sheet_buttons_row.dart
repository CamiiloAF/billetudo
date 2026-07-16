import 'package:flutter/material.dart';

/// The `Sheet Buttons Row` component: the two buttons that close a sheet.
///
/// Which side is primary is **not** fixed: "No se puede eliminar" puts the
/// primary on the left, because in a blocking sheet the dominant action is the
/// one that closes it, not the one that navigates away.
class SheetButtonsRow extends StatelessWidget {
  const SheetButtonsRow({required this.left, required this.right, super.key});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}
