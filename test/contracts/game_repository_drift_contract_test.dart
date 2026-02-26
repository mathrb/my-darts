// Game Repository Hybrid Contract Test
// Runs the shared contract tests against both SQLite and Drift implementations

import 'package:flutter_test/flutter_test.dart';
import '../hybrid_test_runner.dart';
import 'game_repository_contract.dart';

void main() {
  runHybridTests('Game Repository Contract Tests', (base) {
    runGameRepositoryContractTests(() => base.createGameRepository());
  });
}
