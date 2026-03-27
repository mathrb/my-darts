import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/checkout_table.dart';
import '../../domain/models/game_config.dart';
import '../providers/active_game_provider.dart';
import '../widgets/dart_input_grid_widget.dart';
import '../widgets/end_game_dialog_widget.dart';
import '../widgets/leg_complete_modal_widget.dart';
import '../widgets/player_score_section_widget.dart';

class X01BoardPage extends ConsumerStatefulWidget {
  const X01BoardPage({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<X01BoardPage> createState() => _X01BoardPageState();
}

class _X01BoardPageState extends ConsumerState<X01BoardPage>
    with TickerProviderStateMixin {
  late final AnimationController _bustFlashController;
  late final Animation<double> _bustFlashAnim;

  @override
  void initState() {
    super.initState();
    _bustFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _bustFlashAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 300,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 500,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 300,
      ),
    ]).animate(_bustFlashController);
  }

  @override
  void dispose() {
    _bustFlashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Bust listener — fires on showBust false→true transition
    ref.listen(activeGameProvider(widget.gameId), (prev, next) {
      final prevShowBust = prev?.value?.showBust ?? false;
      final nextShowBust = next.value?.showBust ?? false;
      if (!prevShowBust && nextShowBust) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: cs.errorContainer,
            duration: const Duration(seconds: 2),
            content: Text(
              'BUST',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: cs.onErrorContainer),
            ),
          ),
        );
        _bustFlashController.forward(from: 0);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            ref
                .read(activeGameProvider(widget.gameId).notifier)
                .dismissBust();
          }
        });
      }
    });

    // Leg complete listener
    ref.listen(activeGameProvider(widget.gameId), (prev, next) {
      final prevLeg = prev?.value?.pendingLegWinnerId;
      final nextLeg = next.value?.pendingLegWinnerId;
      if (prevLeg == null && nextLeg != null) {
        final gs = next.value!.gameState;
        final winner = gs.competitors.firstWhere(
          (c) => c.competitorId == nextLeg,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => LegCompleteModalWidget(
              winnerName: winner.name,
              legNumber: gs.currentLegIndex,
              onNextLeg: () => ref
                  .read(activeGameProvider(widget.gameId).notifier)
                  .dismissLegModal(),
            ),
          );
        });
      }
    });

    final asyncState = ref.watch(activeGameProvider(widget.gameId));

    return asyncState.when(
      loading: () => Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: $err'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    ref.invalidate(activeGameProvider(widget.gameId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (activeGameState) {
        if (activeGameState == null) {
          return const Scaffold(
            body: Center(child: Text('Game not found')),
          );
        }

        final gameState = activeGameState.gameState;
        final activeCompetitor =
            gameState.competitors[gameState.currentTurnIndex];
        final dartsThrownInTurn = gameState.dartsThrownInTurn;
        final canUndo = dartsThrownInTurn > 0 ||
            gameState.competitors.any((c) => c.dartThrows.isNotEmpty);
        final canNext = !gameState.turnActive && !gameState.isComplete;
        final currentScore = activeCompetitor.score;

        // Current turn darts: last dartsThrownInTurn items from active
        // competitor's dartThrows list
        final allDarts = activeCompetitor.dartThrows;
        final currentTurnDarts =
            dartsThrownInTurn == 0 || allDarts.length < dartsThrownInTurn
                ? <String>[]
                : allDarts.sublist(allDarts.length - dartsThrownInTurn);

        // Winner name for win banner
        final pendingGameWinnerId = activeGameState.pendingGameWinnerId;
        String? winnerName;
        if (pendingGameWinnerId != null) {
          winnerName = gameState.competitors
              .firstWhere((c) => c.competitorId == pendingGameWinnerId)
              .name;
        }

        return Scaffold(
          appBar: _BoardAppBar(
            onBack: () => context.go(GameRoutes.home),
            onSettings: () => _showEndGameDialog(context),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  _GameStatusBar(
                    startingScore: gameState.startingScore,
                    currentLegIndex: gameState.currentLegIndex,
                    legsToWin: gameState.legsToWin,
                    currentTurnDarts: currentTurnDarts,
                  ),
                  PlayerScoreSectionWidget(
                    gameState: gameState,
                    bustFlashAnim: _bustFlashAnim,
                  ),
                  _CheckoutBanner(score: currentScore),
                  Expanded(
                    child: DartInputGridWidget(
                      onSegmentTapped: (segment) => ref
                          .read(activeGameProvider(widget.gameId).notifier)
                          .processDart(segment),
                      enabled: !gameState.isComplete && gameState.turnActive,
                    ),
                  ),
                  _BottomActionBar(
                    canUndo: canUndo,
                    canNext: canNext,
                    isMultiplayer: gameState.competitors.length > 1,
                    onUndo: () => ref
                        .read(activeGameProvider(widget.gameId).notifier)
                        .undoDart(),
                    onNextRound: () {
                      final notifier = ref
                          .read(activeGameProvider(widget.gameId).notifier);
                      notifier.dismissBust();
                      notifier.dismissLegModal();
                      notifier.startNextTurn();
                    },
                  ),
                ],
              ),
              // Win banner (always in stack; slides in when winner set)
              IgnorePointer(
                ignoring: pendingGameWinnerId == null,
                child: _WinBannerWidget(
                  visible: pendingGameWinnerId != null,
                  winnerName: winnerName ?? '',
                  lastDart: gameState.competitors
                      .expand((c) => [
                            if (c.competitorId == pendingGameWinnerId &&
                                c.dartThrows.isNotEmpty)
                              c.dartThrows.last,
                          ])
                      .firstOrNull,
                  onPostGame: () =>
                      context.go('/post-game/${widget.gameId}'),
                  onPlayAgain: () => context.go(GameRoutes.home),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEndGameDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => EndGameDialogWidget(
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          context.go(GameRoutes.home);
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────────

class _BoardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _BoardAppBar({
    required this.onBack,
    required this.onSettings,
  });

  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              splashColor: AppTheme.kineticSplashColor,
              highlightColor: AppTheme.kineticSplashColor,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  semanticLabel: 'Back',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'MYDARTS',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: cs.primaryFixed,
                  letterSpacing: 4,
                ),
              ),
            ),
            InkWell(
              onTap: onSettings,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              splashColor: AppTheme.kineticSplashColor,
              highlightColor: AppTheme.kineticSplashColor,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.settings_outlined,
                  color: Colors.white,
                  semanticLabel: 'Game options',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameStatusBar extends StatelessWidget {
  const _GameStatusBar({
    required this.startingScore,
    required this.currentLegIndex,
    required this.legsToWin,
    required this.currentTurnDarts,
  });

  final int startingScore;
  final int currentLegIndex;
  final int legsToWin;
  final List<String> currentTurnDarts;

  int get _turnSum => currentTurnDarts.isEmpty
      ? 0
      : currentTurnDarts
          .map((s) => Segment.parse(s).scoreValue)
          .fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = AppTextStyles.labelSmall.copyWith(
      color: cs.onSurfaceVariant,
      letterSpacing: 1.2,
      fontSize: 10,
    );
    final dot = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
    );

    final dartsThrown = currentTurnDarts.length;
    final turnSum = _turnSum;
    final lastDart =
        currentTurnDarts.isNotEmpty ? currentTurnDarts.last : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Text('$startingScore', style: labelStyle),
          if (legsToWin > 1) ...[
            dot,
            Text('ROUND ${currentLegIndex + 1} / $legsToWin', style: labelStyle),
          ],
          dot,
          Text('LEG ${currentLegIndex + 1}', style: labelStyle),
          if (dartsThrown > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 1,
                height: 16,
                child: ColoredBox(
                  color: cs.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
            ),
            if (turnSum > 0)
              Text(
                '$turnSum',
                style: AppTextStyles.labelMedium.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            const SizedBox(width: 8),
            if (lastDart != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryFixed.withValues(alpha: 0.1),
                  border: Border.all(
                    color: cs.primaryFixed.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  lastDart,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: cs.primaryFixed,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              '$dartsThrown',
              style: AppTextStyles.labelMedium
                  .copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.navigation,
              size: 14,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              semanticLabel: '',
            ),
          ],
        ],
      ),
    );
  }
}

class _CheckoutBanner extends StatelessWidget {
  const _CheckoutBanner({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visible = score >= 2 && score <= 170;
    final suggestion = visible ? checkoutSuggestion(score) : null;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Visibility(
        visible: visible,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  ColoredBox(
                    color: cs.primaryFixed,
                    child: const SizedBox(width: 2),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CHECKOUT',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: cs.onSurfaceVariant,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            suggestion ?? '',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: cs.primaryFixed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.canUndo,
    required this.canNext,
    required this.isMultiplayer,
    required this.onUndo,
    required this.onNextRound,
  });

  final bool canUndo;
  final bool canNext;
  final bool isMultiplayer;
  final VoidCallback onUndo;
  final VoidCallback onNextRound;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          border: Border(
            top: BorderSide(
              color: cs.surfaceContainer.withValues(alpha: 0.3),
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Row(
          children: [
            // Undo — square button
            Opacity(
              opacity: canUndo ? 1.0 : 0.38,
              child: InkWell(
                onTap: canUndo ? onUndo : null,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                splashColor: AppTheme.kineticSplashColor,
                highlightColor: AppTheme.kineticSplashColor,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.undo,
                    color: cs.onSurface,
                    semanticLabel: 'Undo last dart',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Next player / round — primary neon button
            Expanded(
              child: Opacity(
                opacity: canNext ? 1.0 : 0.38,
                child: InkWell(
                  onTap: canNext ? onNextRound : null,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  splashColor: AppTheme.kineticSplashColor,
                  highlightColor: AppTheme.kineticSplashColor,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: cs.primaryFixed,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLarge),
                      boxShadow: canNext
                          ? [
                              BoxShadow(
                                color: cs.primaryFixed
                                    .withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isMultiplayer ? 'NEXT PLAYER' : 'NEXT ROUND',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: cs.onPrimaryContainer,
                          semanticLabel: '',
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
    );
  }
}

class _WinBannerWidget extends StatelessWidget {
  const _WinBannerWidget({
    required this.visible,
    required this.winnerName,
    required this.lastDart,
    required this.onPostGame,
    required this.onPlayAgain,
  });

  final bool visible;
  final String winnerName;
  final String? lastDart;
  final VoidCallback onPostGame;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      child: ColoredBox(
        color: cs.surfaceContainerLow,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                winnerName.toUpperCase(),
                style: AppTextStyles.displayLarge.copyWith(
                  color: cs.primary,
                ),
              ),
              if (lastDart != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Final Score: 0  ·  Checkout: $lastDart',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: cs.primary,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: onPostGame,
                child: const Text('Post-Game Summary'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onPlayAgain,
                child: const Text('Play Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
