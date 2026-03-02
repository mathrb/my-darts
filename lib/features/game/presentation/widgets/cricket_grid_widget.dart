import 'package:flutter/material.dart';
import '../../domain/models/game_state.dart';
import 'cricket_mark_indicator_widget.dart';

class CricketGridWidget extends StatelessWidget {
  const CricketGridWidget({
    required this.gameState,
    required this.onSegmentTapped,
    super.key,
  });

  final GameState gameState;
  final void Function(String segment) onSegmentTapped;

  static const _rows = ['20', '19', '18', '17', '16', '15', 'Bull'];

  String _segment(String rowKey, int columnIndex) {
    final isBull = rowKey == 'Bull';
    return switch (columnIndex) {
      0 => isBull ? 'SB' : rowKey,
      1 => isBull ? 'DB' : 'D$rowKey',
      _ => isBull ? 'DB' : 'T$rowKey', // no triple bull → maps to DB
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentPlayer = gameState.competitors[gameState.currentTurnIndex];

    return Column(
      children: [
        _buildHeader(textTheme, colorScheme),
        ...List.generate(_rows.length, (rowIndex) {
          final rowKey = _rows[rowIndex];
          final currentMarks = currentPlayer.marksPerNumber[rowKey] ?? 0;
          final currentClosed = currentMarks >= 3;
          final opponentOpen = gameState.competitors
              .whereIndexed((i, c) => i != gameState.currentTurnIndex)
              .any((c) => (c.marksPerNumber[rowKey] ?? 0) < 3);

          return _buildRow(
            context: context,
            rowKey: rowKey,
            currentMarks: currentMarks,
            currentClosed: currentClosed,
            opponentOpen: opponentOpen,
            colorScheme: colorScheme,
            textTheme: textTheme,
          );
        }),
      ],
    );
  }

  Widget _buildHeader(TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const SizedBox(width: 48), // spacer for row-label column
          ...['S', 'D', 'T'].map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required String rowKey,
    required int currentMarks,
    required bool currentClosed,
    required bool opponentOpen,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    Color rowBackground;
    if (currentClosed) {
      rowBackground = Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade700
          : Colors.grey.shade300;
    } else if (opponentOpen) {
      rowBackground = Colors.orange.withOpacity(0.08);
    } else {
      rowBackground = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Center(
              child: Text(
                rowKey,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: currentClosed
                      ? colorScheme.onSurface.withOpacity(0.4)
                      : colorScheme.onSurface,
                ),
              ),
            ),
          ),
          ...List.generate(3, (colIndex) {
            final segment = _segment(rowKey, colIndex);
            final isTripleBull = rowKey == 'Bull' && colIndex == 2;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildCell(
                  context: context,
                  segment: segment,
                  marks: currentMarks,
                  background: rowBackground,
                  isTripleBull: isTripleBull,
                  dimmed: currentClosed,
                  colorScheme: colorScheme,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCell({
    required BuildContext context,
    required String segment,
    required int marks,
    required Color background,
    required bool isTripleBull,
    required bool dimmed,
    required ColorScheme colorScheme,
  }) {
    final effectiveTap = gameState.isComplete
        ? null
        : () => onSegmentTapped(segment);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: effectiveTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: dimmed ? 0.4 : 1.0,
                child: CricketMarkIndicatorWidget(marks: marks),
              ),
              if (isTripleBull)
                Text(
                  '= DB',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 9,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _IterableIndexed<T> on Iterable<T> {
  Iterable<T> whereIndexed(bool Function(int index, T element) test) sync* {
    var index = 0;
    for (final element in this) {
      if (test(index, element)) yield element;
      index++;
    }
  }
}
