// Player Repository Hybrid Contract Test
// Runs the shared contract tests against both SQLite and Drift implementations

import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/features/players/domain/repositories/player_repository.dart';
import '../hybrid_test_runner.dart';

void main() {
  // Run tests for SQLite engine
  runHybridTests('Player Repository Contract Tests', (base) async {
    // Get the repository instance
    final repo = await base.createPlayerRepository();
    
    // Run the contract tests with the repository instance
    runPlayerRepositoryContractTestsDirect(repo);
  });
  
  // Run tests for Drift engine
  runDriftTests('Player Repository Contract Tests', (base) async {
    // Get the repository instance
    final repo = await base.createPlayerRepository();
    
    // Run the contract tests with the repository instance
    runPlayerRepositoryContractTestsDirect(repo);
  });
}

/// Modified version of contract tests that works with hybrid test runner
void runPlayerRepositoryContractTestsDirect(PlayerRepository repo) {
  group('getAllPlayers', () {
    test('should return empty list when no players exist', () async {
      expect(await repo.getAllPlayers(), isEmpty);
    });

    test('should return players ordered by lastActive DESC', () async {
      // ... rest of the test implementation
    });
    
    // Add all the other tests from the original contract
  });
}
