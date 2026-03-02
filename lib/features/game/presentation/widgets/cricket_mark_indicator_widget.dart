import 'package:flutter/material.dart';

class CricketMarkIndicatorWidget extends StatelessWidget {
  const CricketMarkIndicatorWidget({required this.marks, super.key});

  final int marks;

  @override
  Widget build(BuildContext context) {
    final clamped = marks.clamp(0, 3);
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme.onSurface;

    return switch (clamped) {
      0 => Text('–', style: textTheme.bodyLarge?.copyWith(color: color)),
      1 => Text('/', style: textTheme.bodyLarge?.copyWith(color: color)),
      2 => Text('X',
          style: textTheme.bodyLarge
              ?.copyWith(color: color, fontWeight: FontWeight.bold)),
      _ => Text('⊗', style: textTheme.bodyLarge?.copyWith(color: color)),
    };
  }
}
