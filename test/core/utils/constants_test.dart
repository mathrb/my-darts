import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/constants.dart';

void main() {
  group('GameType.maxPlayers', () {
    // Locking down the per-game value so a future GameType addition has to
    // make an explicit choice (the switch is exhaustive now — see #169).
    const expected = <GameType, int?>{
      GameType.x01: 6,
      GameType.cricket: 6,
      GameType.aroundTheClock: null,
      GameType.shanghai: null,
      GameType.catch40: 1,
      GameType.bobs27: 1,
      GameType.checkoutPractice: 1,
      GameType.countUp: 6,
    };

    test('covers every GameType value', () {
      expect(expected.keys.toSet(), GameType.values.toSet());
    });

    for (final entry in expected.entries) {
      test('${entry.key.name} -> ${entry.value}', () {
        expect(entry.key.maxPlayers, entry.value);
      });
    }
  });
}
