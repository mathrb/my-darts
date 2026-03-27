import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';

const _row1 = [20, 19, 18, 17, 16, 15, 14, 13, 12, 11];
const _row2 = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1];

class DartInputGridWidget extends StatelessWidget {
  const DartInputGridWidget({
    required this.onSegmentTapped,
    this.enabled = true,
    super.key,
  });

  final void Function(String segment) onSegmentTapped;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Singles → Doubles → Triples (6 equal rows)
        Expanded(
          child: Column(
            children: [
              // Singles (20–11)
              Expanded(
                child: _NumberRow(
                  numbers: _row1,
                  prefix: '',
                  dots: 0,
                  bgColor: cs.surfaceContainerHighest,
                  textColor: cs.onSurface,
                  onTap: onSegmentTapped,
                  enabled: enabled,
                ),
              ),
              // Singles (10–1)
              Expanded(
                child: _NumberRow(
                  numbers: _row2,
                  prefix: '',
                  dots: 0,
                  bgColor: cs.surfaceContainerHighest,
                  textColor: cs.onSurface,
                  onTap: onSegmentTapped,
                  enabled: enabled,
                ),
              ),
              // Doubles (D20–D11)
              Expanded(
                child: _NumberRow(
                  numbers: _row1,
                  prefix: 'D',
                  dots: 2,
                  bgColor: cs.surfaceContainerLow,
                  textColor: cs.onSurfaceVariant,
                  dotColor: cs.primaryFixed.withValues(alpha: 0.7),
                  onTap: onSegmentTapped,
                  enabled: enabled,
                ),
              ),
              // Doubles (D10–D1)
              Expanded(
                child: _NumberRow(
                  numbers: _row2,
                  prefix: 'D',
                  dots: 2,
                  bgColor: cs.surfaceContainerLow,
                  textColor: cs.onSurfaceVariant,
                  dotColor: cs.primaryFixed.withValues(alpha: 0.7),
                  onTap: onSegmentTapped,
                  enabled: enabled,
                ),
              ),
              // Triples (T20–T11)
              Expanded(
                child: _NumberRow(
                  numbers: _row1,
                  prefix: 'T',
                  dots: 3,
                  bgColor: cs.surfaceContainer,
                  textColor: cs.onSurfaceVariant,
                  dotColor: cs.primaryFixed.withValues(alpha: 0.7),
                  onTap: onSegmentTapped,
                  enabled: enabled,
                ),
              ),
              // Triples (T10–T1)
              Expanded(
                child: _NumberRow(
                  numbers: _row2,
                  prefix: 'T',
                  dots: 3,
                  bgColor: cs.surfaceContainer,
                  textColor: cs.onSurfaceVariant,
                  dotColor: cs.primaryFixed.withValues(alpha: 0.7),
                  onTap: onSegmentTapped,
                  enabled: enabled,
                ),
              ),
            ],
          ),
        ),
        // Special buttons row
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Miss
              Expanded(
                flex: 2,
                child: Semantics(
                  label: 'Miss',
                  child: InkWell(
                    onTap: enabled ? () => onSegmentTapped('MISS') : null,
                    splashColor: AppTheme.kineticSplashColor,
                    highlightColor: AppTheme.kineticSplashColor,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'MISS',
                        style: AppTextStyles.segmentButton
                            .copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ),
              // Single Bull (25)
              Expanded(
                flex: 3,
                child: Semantics(
                  label: 'Single Bull',
                  child: InkWell(
                    onTap: enabled ? () => onSegmentTapped('SB') : null,
                    splashColor: AppTheme.kineticSplashColor,
                    highlightColor: AppTheme.kineticSplashColor,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.1),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '25',
                            style: AppTextStyles.segmentButton
                                .copyWith(color: cs.onSurface),
                          ),
                          Text(
                            'BULL',
                            style: AppTextStyles.multiplierLabel
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Double Bull (50)
              Expanded(
                flex: 3,
                child: Semantics(
                  label: 'Double Bull',
                  child: InkWell(
                    onTap: enabled ? () => onSegmentTapped('DB') : null,
                    splashColor: AppTheme.kineticSplashColor,
                    highlightColor: AppTheme.kineticSplashColor,
                    child: Container(
                      color: cs.primaryFixed,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '50',
                            style: AppTextStyles.segmentButton
                                .copyWith(color: cs.onPrimaryContainer),
                          ),
                          Text(
                            'D-BULL',
                            style: AppTextStyles.multiplierLabel.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.numbers,
    required this.prefix,
    required this.dots,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
    required this.enabled,
    this.dotColor,
  });

  final List<int> numbers;
  final String prefix;
  final int dots;
  final Color bgColor;
  final Color textColor;
  final Color? dotColor;
  final void Function(String) onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final n in numbers)
          _GridCell(
            label: '$prefix$n',
            segment: '$prefix$n',
            semanticLabel: '${prefix.isEmpty ? 'Single' : prefix == 'D' ? 'Double' : 'Triple'} $n',
            bgColor: bgColor,
            textColor: textColor,
            dots: dots,
            dotColor: dotColor ?? textColor,
            onTap: onTap,
            enabled: enabled,
          ),
      ],
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.label,
    required this.segment,
    required this.semanticLabel,
    required this.bgColor,
    required this.textColor,
    required this.dots,
    required this.dotColor,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final String segment;
  final String semanticLabel;
  final Color bgColor;
  final Color textColor;
  final int dots;
  final Color dotColor;
  final void Function(String) onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        label: semanticLabel,
        child: InkWell(
          onTap: enabled ? () => onTap(segment) : null,
          splashColor: AppTheme.kineticSplashColor,
          highlightColor: AppTheme.kineticSplashColor,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                right: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.15),
                ),
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTextStyles.segmentButton.copyWith(color: textColor),
                ),
                if (dots > 0) ...[
                  const SizedBox(height: 2),
                  _DotRow(count: dots, color: dotColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DotRow extends StatelessWidget {
  const _DotRow({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
