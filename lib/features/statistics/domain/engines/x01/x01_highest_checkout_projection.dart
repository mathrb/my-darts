import 'dart:math';

import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';

class X01HighestCheckoutProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01_highest_checkout',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'LegCompleted'},
    scope: ProjectionScope.match,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _highestCheckout = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _highestCheckout = 0;
  }

  @override
  void apply(GameEvent event) {
    if (event.eventType != 'LegCompleted') return;
    final winnerId = event.payload['winner_player_id'] as String?;
    if (winnerId != _context?.playerId) return;
    final checkoutScore =
        (event.payload['checkout_score'] as num?)?.toInt() ?? 0;
    _highestCheckout = max(_highestCheckout, checkoutScore);
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.match) {
      _highestCheckout = 0;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'highestCheckout': _highestCheckout > 0 ? _highestCheckout : null,
    };
  }
}
