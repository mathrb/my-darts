import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';

class PlayerScoreSectionWidget extends StatelessWidget {
  const PlayerScoreSectionWidget({
    required this.gameState,
    required this.bustFlashAnim,
    super.key,
  });

  final GameState gameState;
  final Animation<double> bustFlashAnim;

  String _pprDisplay(CompetitorState cs) {
    if (cs.dartThrows.length < 3) return '—';
    final totalReduction = gameState.startingScore - cs.score;
    return ((totalReduction / cs.dartThrows.length) * 3).toStringAsFixed(1);
  }

  TextStyle _activeScoreStyle(BuildContext context) {
    final n = gameState.competitors.length;
    if (n == 1) return AppTextStyles.scoreActive(context);
    if (n == 2) return AppTextStyles.scoreLarge(context);
    if (n <= 4) return AppTextStyles.scoreMedium(context);
    return AppTextStyles.scoreSmall(context);
  }

  TextStyle _inactiveScoreStyle(BuildContext context) {
    final n = gameState.competitors.length;
    if (n == 1) return AppTextStyles.scoreInactive(context);
    if (n == 2) return AppTextStyles.scoreMedium(context);
    if (n <= 4) return AppTextStyles.scoreSmall(context);
    return AppTextStyles.scoreSmall(context);
  }

  int _roundSum(CompetitorState cs, bool isActive) {
    if (!isActive) return 0;
    final n = gameState.dartsThrownInTurn;
    if (n == 0) return 0;
    final darts = cs.dartThrows.length < n
        ? cs.dartThrows
        : cs.dartThrows.sublist(cs.dartThrows.length - n);
    return darts
        .map((s) => Segment.parse(s).scoreValue)
        .fold(0, (a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    final activeStyle = _activeScoreStyle(context);
    final inactiveStyle = _inactiveScoreStyle(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < gameState.competitors.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _PlayerCard(
                competitor: gameState.competitors[i],
                isActive: i == gameState.currentTurnIndex,
                scoreStyle: i == gameState.currentTurnIndex
                    ? activeStyle
                    : inactiveStyle,
                roundSum: _roundSum(
                  gameState.competitors[i],
                  i == gameState.currentTurnIndex,
                ),
                pprDisplay: _pprDisplay(gameState.competitors[i]),
                bustFlashAnim: bustFlashAnim,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.competitor,
    required this.isActive,
    required this.scoreStyle,
    required this.roundSum,
    required this.pprDisplay,
    required this.bustFlashAnim,
  });

  final CompetitorState competitor;
  final bool isActive;
  final TextStyle scoreStyle;
  final int roundSum;
  final String pprDisplay;
  final Animation<double> bustFlashAnim;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final stack = Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isActive ? cs.surfaceContainerLow : cs.surfaceContainer,
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: isActive
                    ? cs.primaryFixed.withValues(alpha: 0.2)
                    : cs.outlineVariant.withValues(alpha: 0.1),
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        competitor.name.toUpperCase(),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isActive ? cs.primaryFixed : cs.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'PPR',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 8,
                          ),
                        ),
                        Text(
                          pprDisplay,
                          style: AppTextStyles.labelMedium
                              .copyWith(color: cs.onSurface),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isActive && roundSum > 0)
                  Text(
                    '-$roundSum',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: cs.primaryFixed.withValues(alpha: 0.7),
                    ),
                  ),
                _AnimatedScore(
                  score: competitor.score,
                  style: scoreStyle.copyWith(
                    color: isActive ? cs.onSurface : cs.onSurfaceVariant,
                    shadows: isActive
                        ? [
                            Shadow(
                              color:
                                  cs.primaryFixed.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: cs.primaryFixed,
                  borderRadius: const BorderRadius.only(
                    topLeft:
                        Radius.circular(AppTheme.radiusLarge),
                    bottomLeft:
                        Radius.circular(AppTheme.radiusLarge),
                  ),
                ),
              ),
            ),
          if (isActive)
            AnimatedBuilder(
              animation: bustFlashAnim,
              builder: (context, _) {
                if (bustFlashAnim.value == 0.0) return const SizedBox.shrink();
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.errorContainer
                            .withValues(alpha: bustFlashAnim.value * 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(
                          color:
                              cs.error.withValues(alpha: bustFlashAnim.value),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
    );
    return isActive ? stack : Opacity(opacity: 0.7, child: stack);
  }
}

class _AnimatedScore extends StatefulWidget {
  const _AnimatedScore({required this.score, required this.style});

  final int score;
  final TextStyle style;

  @override
  State<_AnimatedScore> createState() => _AnimatedScoreState();
}

class _AnimatedScoreState extends State<_AnimatedScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Tween<double> _tween;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _tween = Tween<double>(
      begin: widget.score.toDouble(),
      end: widget.score.toDouble(),
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_AnimatedScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _tween = Tween<double>(
        begin: oldWidget.score.toDouble(),
        end: widget.score.toDouble(),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text('${widget.score}', style: widget.style);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _tween.evaluate(_controller).round();
        return Text('$value', style: widget.style);
      },
    );
  }
}
