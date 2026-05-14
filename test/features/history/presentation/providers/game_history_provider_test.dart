import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/repositories/game_repository.dart';
import 'package:dart_lodge/features/history/presentation/providers/game_history_provider.dart';

import 'game_history_provider_test.mocks.dart';

@GenerateMocks([GameRepository])
void main() {
  late MockGameRepository repo;
  late ProviderContainer container;

  Game _game(String id, DateTime endTime) => Game(
        gameId: id,
        gameType: GameType.x01,
        config: const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'straight',
          outStrategy: 'double',
          legsToWin: 1,
        ),
        startTime: endTime.subtract(const Duration(minutes: 15)),
        endTime: endTime,
        isComplete: true,
      );

  setUp(() {
    repo = MockGameRepository();
    when(repo.getCompetitors(any)).thenAnswer((_) async => []);
    when(repo.getCompletedGames(
      limit: anyNamed('limit'),
      offset: anyNamed('offset'),
      filterByType: anyNamed('filterByType'),
      dateFrom: anyNamed('dateFrom'),
      dateTo: anyNamed('dateTo'),
    )).thenAnswer((_) async => []);
    container = ProviderContainer(overrides: [
      gameRepositoryProvider.overrideWithValue(repo),
    ]);
  });

  tearDown(() => container.dispose());

  group('Date filter is pushed into the repository (regression for #171)', () {
    test('build() forwards dateFrom and dateTo to getCompletedGames', () async {
      final from = DateTime(2026, 5, 1);
      final to = DateTime(2026, 5, 14);

      container.read(gameHistoryProvider.notifier).setDateRange(from, to);
      await container.read(gameHistoryProvider.future);

      verify(repo.getCompletedGames(
        limit: 20,
        offset: 0,
        filterByType: null,
        dateFrom: from,
        dateTo: to,
      )).called(greaterThanOrEqualTo(1));
    });

    test('loadNextPage forwards date filter and offsets by displayed rows',
        () async {
      // First page: 20 rows so hasMore == true.
      final firstPage =
          List.generate(20, (i) => _game('g$i', DateTime(2026, 5, 14 - i)));
      final from = DateTime(2026, 5, 1);

      when(repo.getCompletedGames(
        limit: anyNamed('limit'),
        offset: 0,
        filterByType: anyNamed('filterByType'),
        dateFrom: anyNamed('dateFrom'),
        dateTo: anyNamed('dateTo'),
      )).thenAnswer((_) async => firstPage);
      when(repo.getCompletedGames(
        limit: anyNamed('limit'),
        offset: 20,
        filterByType: anyNamed('filterByType'),
        dateFrom: anyNamed('dateFrom'),
        dateTo: anyNamed('dateTo'),
      )).thenAnswer((_) async => []);

      container.read(gameHistoryProvider.notifier).setDateRange(from, null);
      await container.read(gameHistoryProvider.future);

      await container.read(gameHistoryProvider.notifier).loadNextPage();

      verify(repo.getCompletedGames(
        limit: 20,
        offset: 20,
        filterByType: null,
        dateFrom: from,
        dateTo: null,
      )).called(1);
    });
  });

  group('loadNextPage in-flight guard (regression for #171)', () {
    test('rapid parallel calls only trigger a single repo fetch', () async {
      final firstPage =
          List.generate(20, (i) => _game('g$i', DateTime(2026, 5, 14 - i)));
      final secondPage =
          List.generate(20, (i) => _game('h$i', DateTime(2026, 4, 14 - i)));

      when(repo.getCompletedGames(
        limit: anyNamed('limit'),
        offset: 0,
        filterByType: anyNamed('filterByType'),
        dateFrom: anyNamed('dateFrom'),
        dateTo: anyNamed('dateTo'),
      )).thenAnswer((_) async => firstPage);
      when(repo.getCompletedGames(
        limit: anyNamed('limit'),
        offset: 20,
        filterByType: anyNamed('filterByType'),
        dateFrom: anyNamed('dateFrom'),
        dateTo: anyNamed('dateTo'),
      )).thenAnswer((_) async => secondPage);

      await container.read(gameHistoryProvider.future);

      final notifier = container.read(gameHistoryProvider.notifier);
      // Fire three calls back-to-back in the same event-loop tick — what
      // the ScrollController will do near the bottom of the list.
      final f1 = notifier.loadNextPage();
      final f2 = notifier.loadNextPage();
      final f3 = notifier.loadNextPage();
      await Future.wait([f1, f2, f3]);

      verify(repo.getCompletedGames(
        limit: 20,
        offset: 20,
        filterByType: null,
        dateFrom: null,
        dateTo: null,
      )).called(1);

      // And the second page is not duplicated in state.
      final games = container.read(gameHistoryProvider).value!.games;
      expect(games, hasLength(40),
          reason: 'page 1 (20) + page 2 (20) — no duplicate rows');
    });
  });
}
