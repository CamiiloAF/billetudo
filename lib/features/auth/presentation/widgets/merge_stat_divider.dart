import 'package:flutter/material.dart';

class MergeStatDivider extends StatelessWidget {
  const MergeStatDivider({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 40, child: VerticalDivider(color: color, width: 1));
}
