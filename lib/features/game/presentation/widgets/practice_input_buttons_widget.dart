import 'package:flutter/material.dart';
import '../../../../core/utils/constants.dart';

class PracticeInputButtonsWidget extends StatelessWidget {
  const PracticeInputButtonsWidget({
    required this.gameType,
    required this.currentTarget,
    required this.onDartThrown,
    required this.enabled,
    super.key,
  });

  final GameType gameType;
  final int? currentTarget;
  final void Function(String segment) onDartThrown;
  final bool enabled;

  bool get _isBobs27 => gameType == GameType.bobs27;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final n = currentTarget;

    final buttons = [
      _ButtonSpec(
        label: n != null ? 'S-$n' : 'S',
        segment: n != null ? '$n' : 'S',
        dimmed: _isBobs27,
      ),
      _ButtonSpec(
        label: n != null ? 'D-$n' : 'D',
        segment: n != null ? 'D$n' : 'D$n',
        dimmed: false,
      ),
      _ButtonSpec(
        label: n != null ? 'T-$n' : 'T',
        segment: n != null ? 'T$n' : 'T$n',
        dimmed: _isBobs27,
      ),
      const _ButtonSpec(
        label: 'MISS',
        segment: 'MISS',
        dimmed: false,
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: enabled
                  ? () => onDartThrown(buttons[i].segment)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                buttons[i].label,
                style: buttons[i].dimmed
                    ? TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.4),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ButtonSpec {
  const _ButtonSpec({
    required this.label,
    required this.segment,
    required this.dimmed,
  });

  final String label;
  final String segment;
  final bool dimmed;
}
