// Process Practice Dart Use Case
// Business logic for handling a dart throw event in practice game types
// (Around the Clock, Bob's 27, Shanghai, Catch 40, Checkout Practice).
// Uses the abstract GameEngine interface — no TurnEnded/TurnStarted wrapping.

import '../entities/game_event.dart';
import '../entities/dart_throw.dart';
import '../repositories/game_repository.dart';
import '../repositories/game_event_repository.dart';
import '../repositories/dart_throw_repository.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../engines/base_game_engine.dart';
import '../../../../core/error/repository_exception.dart';
import 'game_use_case_helpers.dart';
import 'package:uuid/uuid.dart';
import 'package:my_darts/core/utils/constants.dart';

class ProcessPracticeDartUseCase {
  final GameRepository _gameRepository;
  final GameEventRepository _eventRepository;
  final DartThrowRepository _dartThrowRepository;
  final GameEngine _engine;

  ProcessPracticeDartUseCase(
    this._gameRepository,
    this._eventRepository,
    this._dartThrowRepository,
    this._engine,
  );

  Future<GameState> execute(GameState currentState, DartThrow dartThrow) async {
    // 1. Guard: game already complete
    if (currentState.isComplete) {
      throw GameAlreadyCompleteException(currentState.gameId);
    }

    // 2. Parse segment to extract base number and multiplier
    final parsedSegment = Segment.parse(dartThrow.segment);
    final segmentValue = parsedSegment.baseNumber;
    final multiplier = parsedSegment.multiplier;

    // 3. Fetch sequence counter
    int nextSeq =
        await _eventRepository.getLatestSequence(currentState.gameId) + 1;

    // 4. Build DartThrown event
    final currentPlayerId = getCurrentPlayerId(currentState, dartThrow.competitorId);

    final dartEvent = GameEvent(
      eventId: dartThrow.dartId,
      gameId: currentState.gameId,
      eventType: 'DartThrown',
      localSequence: nextSeq++,
      occurredAt: DateTime.now(),
      payload: {
        'competitor_id': dartThrow.competitorId,
        'segment': segmentValue,
        'multiplier': multiplier,
        'input_method': 'manual',
      },
      synced: false,
      actorId: currentPlayerId,
      source: EventSource.client,
    );

    // 5. Apply DartThrown through engine
    final result = _engine.apply(currentState, dartEvent);
    final eventsToStore = <GameEvent>[dartEvent];
    var finalState = result.state;

    // 6. Persist dart
    await _dartThrowRepository.insertDart(dartThrow);

    // 7. If game completed, append GameCompleted and call completeGame
    if (result.outcome == LegOutcome.gameCompleted) {
      final gameCompletedEvent = GameEvent(
        eventId: const Uuid().v4(),
        gameId: currentState.gameId,
        eventType: 'GameCompleted',
        localSequence: nextSeq++,
        occurredAt: DateTime.now(),
        payload: {'winner_id': result.winnerCompetitorId},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );
      eventsToStore.add(gameCompletedEvent);
      finalState = _engine.apply(finalState, gameCompletedEvent).state;

      await _eventRepository.appendEvents(eventsToStore);

      await _gameRepository.completeGame(
        gameId: currentState.gameId,
        winnerCompetitorId: result.winnerCompetitorId,
        endTime: DateTime.now(),
      );

      return finalState;
    }

    // 8. If leg boundary (but not game over), append LegCompleted
    if (result.state.currentLegIndex > currentState.currentLegIndex) {
      final legCompletedEvent = GameEvent(
        eventId: const Uuid().v4(),
        gameId: currentState.gameId,
        eventType: 'LegCompleted',
        localSequence: nextSeq++,
        occurredAt: DateTime.now(),
        payload: {'winner_competitor_id': result.winnerCompetitorId},
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );
      eventsToStore.add(legCompletedEvent);
      finalState = _engine.apply(finalState, legCompletedEvent).state;
    }

    // 9. Persist events and return
    await _eventRepository.appendEvents(eventsToStore);

    return finalState;
  }

}
