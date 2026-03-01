import 'package:flutter/material.dart';

class DartIndicatorWidget extends StatelessWidget {
  const DartIndicatorWidget({
    required this.dartsThrown,
    super.key,
  }) : assert(dartsThrown >= 0 && dartsThrown <= 3);

  final int dartsThrown;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) => _DartSlot(filled: index < dartsThrown)),
    );
  }
}

class _DartSlot extends StatelessWidget {
  const _DartSlot({required this.filled});

  final bool filled;

  static const Color _filledColor = Color(0xFFFFB74D);
  static const Color _emptyColor = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '────',
          style: TextStyle(
            color: filled ? _filledColor : _emptyColor,
            fontSize: 16,
          ),
        ),
        if (filled)
          const Text(
            '🎯',
            style: TextStyle(fontSize: 20),
          ),
      ],
    );
  }
}
