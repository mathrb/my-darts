// Drift Web Implementation Test
// Tests the drift implementation for web

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/core/persistence/drift/drift_helper.dart';
import 'package:my_darts/core/persistence/drift/repositories/player_repository_drift.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';

void main() {
  group('Drift Web Implementation', () {
    late DriftHelper driftHelper;
    late PlayerRepositoryDrift playerRepo;

    setUp(() async {
      driftHelper = DriftHelper.instance;
      final db = await driftHelper.database;
      playerRepo = PlayerRepositoryDrift(db);
    });

    tearDown(() async {
      await driftHelper.close();
    });

    test('Drift database should initialize', () async {
      final db = await driftHelper.database;
      expect(db, isNotNull);
    });

    test('Player repository should work with drift', () async {
      final player = Player(
        playerId: 'test-player-1',
        name: 'Test Player',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );

      // Create player
      await playerRepo.createPlayer(player);

      // Get player
      final retrieved = await playerRepo.getPlayer('test-player-1');
      expect(retrieved, isNotNull);
      expect(retrieved?.name, 'Test Player');

      // Get all players
      final allPlayers = await playerRepo.getAllPlayers();
      expect(allPlayers.length, 1);
    });
  });
}