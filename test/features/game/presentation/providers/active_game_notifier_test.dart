import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_darts/core/persistence/database_provider.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/competitor.dart';
import 'package:my_darts/features/game/domain/entities/game.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/domain/repositories/dart_throw_repository.dart';
import 'package:my_darts/features/game/domain/repositories/game_event_repository.dart';
import 'package:my_darts/features/game/domain/repositories/game_repository.dart';
import 'package:my_darts/features/game/presentation/providers/active_game_provider.dart';
import 'package:riverpod/riverpod.dart';

import 'active_game_notifier_test.mocks.dart';

@GenerateMocks([GameRepository, GameEventRepository, DartThrowRepository])
void main() {
  late ProviderContainer container;
  late MockGameRepository mockGameRepo;
  late MockGameEventRepository mockEventRepo;
  late MockDartThrowRepository mockDartRepo;

  // ── helpers ──────────────────────────────────────────────────────────────

  Game makeGame({int legsToWin = 1}) => Game(
        gameId: 'g1',
        gameType: GameType.x01,
        config: GameConfig.x01(
          startingScore: 40,
          inStrategy: 'straight',
          outStrategy: 'double',
          legsToWin: legsToWin,
        ),
        startTime: DateTime(2025),
      );

  List<Competitor> makeCompetitors() => [
        Competitor(
          competitorId: 'c1',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'Player 1',
          players: [CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
        ),
        Competitor(
          competitorId: 'c2',
          gameId: 'g1',
          type: CompetitorType.solo,
          name: 'Player 2',
          players: [CompetitorPlayer(playerId: 'p2', rotationPosition: 0)],
        ),
      ];

  GameEvent turnStartedEvent({String competitorId = 'c1', int seq = 1}) =>
      GameEvent(
        eventId: 'e-turn-$seq',
        gameId: 'g1',
        eventType: 'TurnStarted',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {
          'competitor_id': competitorId,
          'turn_index': 0,
          'leg_index': 0,
        },
        synced: false,
        actorId: 'system',
        source: EventSource.client,
      );

  GameEvent dartThrownEvent({
    required int segment,
    required int multiplier,
    int seq = 2,
    String eventId = 'e-dart',
  }) =>
      GameEvent(
        eventId: eventId,
        gameId: 'g1',
        eventType: 'DartThrown',
        localSequence: seq,
        occurredAt: DateTime(2025),
        payload: {
          'competitor_id': 'c1',
          'segment': segment,
          'multiplier': multiplier,
          'input_method': 'manual',
        },
        synced: false,
        actorId: 'p1',
        source: EventSource.client,
      );

  void stubBuild({
    int legsToWin = 1,
    List<GameEvent> events = const [],
  }) {
    when(mockGameRepo.getGame('g1'))
        .thenAnswer((_) async => makeGame(legsToWin: legsToWin));
    when(mockGameRepo.getCompetitors('g1'))
        .thenAnswer((_) async => makeCompetitors());
    when(mockEventRepo.getEventsForGame('g1'))
        .thenAnswer((_) async => events);
  }

  setUp(() {
    mockGameRepo = MockGameRepository();
    mockEventRepo = MockGameEventRepository();
    mockDartRepo = MockDartThrowRepository();

    // Common stubs shared across tests
    when(mockEventRepo.getLatestSequence(any)).thenAnswer((_) async => 1);
    when(mockDartRepo.insertDart(any)).thenAnswer((_) async {});
    when(mockEventRepo.appendEvents(any)).thenAnswer((_) async {});
    when(mockEventRepo.appendEvent(any)).thenAnswer((_) async {});
    when(mockDartRepo.deleteDart(any)).thenAnswer((_) async {});
    when(mockGameRepo.completeGame(
      gameId: anyNamed('gameId'),
      winnerCompetitorId: anyNamed('winnerCompetitorId'),
      endTime: anyNamed('endTime'),
    )).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        gameRepositoryProvider.overrideWithValue(mockGameRepo),
        gameEventRepositoryProvider.overrideWithValue(mockEventRepo),
        dartThrowRepositoryProvider.overrideWithValue(mockDartRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  // ── 1. build returns null when game not found ─────────────────────────────

  test('build returns null when getGame returns null', () async {
    when(mockGameRepo.getGame('g1')).thenAnswer((_) async => null);

    final result = await container.read(activeGameProvider('g1').future);

    expect(result, isNull);
  });

  // ── 2. build replays TurnStarted and returns ActiveGameState ──────────────

  test('build replays TurnStarted event and returns ActiveGameState', () async {
    stubBuild(events: [turnStartedEvent()]);

    final result = await container.read(activeGameProvider('g1').future);

    expect(result, isNotNull);
    expect(result!.gameState.turnActive, true);
    expect(result.gameState.currentTurnIndex, 0);
    expect(result.gameState.competitors[0].score, 40);
    expect(result.showBust, false);
    expect(result.pendingLegWinnerId, null);
    expect(result.pendingGameWinnerId, null);
  });

  // ── 3. processDart updates score ─────────────────────────────────────────

  test('processDart updates score when dart scores', () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);

    await container.read(activeGameProvider('g1').notifier).processDart('20');

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.gameState.competitors[0].score, 20);
    expect(s.showBust, false);
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
  });

  // ── 4. processDart sets showBust on bust ──────────────────────────────────

  test('processDart sets showBust when dart busts (T20 from 40)', () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);

    // T20 = 60 > 40 → bust; score restored to turnStartScore = 40
    await container.read(activeGameProvider('g1').notifier).processDart('T20');

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.showBust, true);
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
  });

  // ── 5. processDart sets pendingLegWinnerId on leg completion ─────────────

  test('processDart sets pendingLegWinnerId when leg completes (not game)',
      () async {
    stubBuild(legsToWin: 2, events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);

    // D20 = 40 = exact checkout; legsToWin:2 so only leg ends
    await container.read(activeGameProvider('g1').notifier).processDart('D20');

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.pendingLegWinnerId, 'c1');
    expect(s.pendingGameWinnerId, null);
    expect(s.showBust, false);
  });

  // ── 6. processDart sets pendingGameWinnerId on game completion ───────────

  test('processDart sets pendingGameWinnerId when game completes', () async {
    stubBuild(legsToWin: 1, events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);

    // D20 = 40 = exact checkout; legsToWin:1 → game complete
    await container.read(activeGameProvider('g1').notifier).processDart('D20');

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.pendingGameWinnerId, 'c1');
    expect(s.pendingLegWinnerId, null);
    expect(s.showBust, false);
  });

  // ── 7. undoDart reverts gameState and clears overlays ────────────────────

  test('undoDart reverts gameState and resets all overlays', () async {
    final events = [
      turnStartedEvent(),
      dartThrownEvent(segment: 20, multiplier: 1), // score: 40-20=20
    ];
    stubBuild(events: events);
    await container.read(activeGameProvider('g1').future);

    // Verify dart was replayed
    final before = container.read(activeGameProvider('g1')).value!;
    expect(before.gameState.competitors[0].score, 20);
    expect(before.gameState.dartsThrownInTurn, 1);

    await container.read(activeGameProvider('g1').notifier).undoDart();

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.gameState.competitors[0].score, 40);
    expect(s.gameState.dartsThrownInTurn, 0);
    expect(s.showBust, false);
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
  });

  // ── 8. dismissBust clears showBust ───────────────────────────────────────

  test('dismissBust sets showBust to false, other fields unchanged', () async {
    stubBuild(events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);
    // Trigger bust
    await container.read(activeGameProvider('g1').notifier).processDart('T20');
    final afterBust = container.read(activeGameProvider('g1')).value!;
    expect(afterBust.showBust, true);

    container.read(activeGameProvider('g1').notifier).dismissBust();

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.showBust, false);
    expect(s.pendingLegWinnerId, null);
    expect(s.pendingGameWinnerId, null);
    // gameState unchanged
    expect(s.gameState, afterBust.gameState);
  });

  // ── 9. dismissLegModal clears pendingLegWinnerId ──────────────────────────

  test('dismissLegModal sets pendingLegWinnerId to null, other fields unchanged',
      () async {
    stubBuild(legsToWin: 2, events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);
    await container.read(activeGameProvider('g1').notifier).processDart('D20');
    final afterLeg = container.read(activeGameProvider('g1')).value!;
    expect(afterLeg.pendingLegWinnerId, 'c1');

    container.read(activeGameProvider('g1').notifier).dismissLegModal();

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.pendingLegWinnerId, null);
    expect(s.showBust, false);
    expect(s.pendingGameWinnerId, null);
    expect(s.gameState, afterLeg.gameState);
  });

  // ── 10. dismissGameModal clears pendingGameWinnerId ───────────────────────

  test(
      'dismissGameModal sets pendingGameWinnerId to null, other fields unchanged',
      () async {
    stubBuild(legsToWin: 1, events: [turnStartedEvent()]);
    await container.read(activeGameProvider('g1').future);
    await container.read(activeGameProvider('g1').notifier).processDart('D20');
    final afterGame = container.read(activeGameProvider('g1')).value!;
    expect(afterGame.pendingGameWinnerId, 'c1');

    container.read(activeGameProvider('g1').notifier).dismissGameModal();

    final s = container.read(activeGameProvider('g1')).value!;
    expect(s.pendingGameWinnerId, null);
    expect(s.showBust, false);
    expect(s.pendingLegWinnerId, null);
    expect(s.gameState, afterGame.gameState);
  });

  // ── 11. build replays DartThrown correctly ───────────────────────────────

  test('build replays DartThrown event and reduces score', () async {
    stubBuild(events: [
      turnStartedEvent(),
      dartThrownEvent(segment: 20, multiplier: 1), // 40-20=20
    ]);

    final result = await container.read(activeGameProvider('g1').future);

    expect(result, isNotNull);
    expect(result!.gameState.competitors[0].score, 20);
    expect(result.gameState.dartsThrownInTurn, 1);
    expect(result.gameState.turnActive, true);
  });
}
