import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../domain/models/game_config.dart';

class DartIndicatorWidget extends StatelessWidget {
  const DartIndicatorWidget({
    required this.currentTurnDarts,
    super.key,
  });

  /// 0–3 canonical segment strings (e.g. 'T20', 'D5', '19', 'SB', 'MISS')
  final List<String> currentTurnDarts;

  int get _roundSum => currentTurnDarts
      .map((s) => Segment.parse(s).scoreValue)
      .fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sum = _roundSum;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            child: sum > 0
                ? Text(
                    '$sum',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: cs.primaryFixed,
                      shadows: [
                        Shadow(
                          color: cs.primaryFixed.withValues(alpha: AppTheme.opacityScoreNumeralShadow),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          ...List.generate(
            3,
            (i) => _DartSlot(
              segment: i < currentTurnDarts.length ? currentTurnDarts[i] : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DartSlot extends StatelessWidget {
  const _DartSlot({required this.segment});

  /// Null = empty slot; non-null = thrown dart segment string.
  final String? segment;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFilled = segment != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isFilled
            ? cs.surfaceContainerHighest
            : cs.outlineVariant.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: isFilled
            ? null
            : Border.all(color: cs.outlineVariant.withValues(alpha: AppTheme.opacityGhostBorderStrong)),
      ),
      child: Text(
        segment ?? '—',
        style: AppTextStyles.segmentButton.copyWith(
          color: isFilled
              ? cs.primaryFixed
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
