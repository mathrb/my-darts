import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/checkout_table.dart';

void main() {
  group('checkoutSuggestionForStrategy', () {
    group('double out', () {
      test('returns suggestion for score in range', () {
        expect(checkoutSuggestionForStrategy(170, 'double'), 'T20 · T20 · DB');
        expect(checkoutSuggestionForStrategy(100, 'double'), 'T20 · D20');
        expect(checkoutSuggestionForStrategy(50, 'double'), 'DB');
        expect(checkoutSuggestionForStrategy(2, 'double'), 'D1');
      });

      test('returns null outside range', () {
        expect(checkoutSuggestionForStrategy(1, 'double'), isNull);
        expect(checkoutSuggestionForStrategy(171, 'double'), isNull);
        expect(checkoutSuggestionForStrategy(0, 'double'), isNull);
      });
    });

    group('straight out', () {
      test('scores 1-20 use singles', () {
        expect(checkoutSuggestionForStrategy(1, 'straight'), 'S1');
        expect(checkoutSuggestionForStrategy(10, 'straight'), 'S10');
        expect(checkoutSuggestionForStrategy(20, 'straight'), 'S20');
      });

      test('score 25 is SB', () {
        expect(checkoutSuggestionForStrategy(25, 'straight'), 'SB');
      });

      test('score 50 is DB', () {
        expect(checkoutSuggestionForStrategy(50, 'straight'), 'DB');
      });

      test('score 180 is T20 · T20 · T20', () {
        expect(
          checkoutSuggestionForStrategy(180, 'straight'),
          'T20 · T20 · T20',
        );
      });

      test('2-dart routes prefer ending on singles', () {
        // Score 80: T20 + S20 (not T20 + D10 like double-out)
        expect(checkoutSuggestionForStrategy(80, 'straight'), 'T20 · S20');
        // Score 70: T20 + S10 (not T18 + D8 like double-out)
        expect(checkoutSuggestionForStrategy(70, 'straight'), 'T20 · S10');
      });

      test('returns null for score 0 and negative', () {
        expect(checkoutSuggestionForStrategy(0, 'straight'), isNull);
        expect(checkoutSuggestionForStrategy(-1, 'straight'), isNull);
      });

      test('returns null for scores above 180', () {
        expect(checkoutSuggestionForStrategy(181, 'straight'), isNull);
      });
    });

    group('master out', () {
      test('score 3 is T1 (not S1 · D1 like double-out)', () {
        expect(checkoutSuggestionForStrategy(3, 'master'), 'T1');
      });

      test('score 9 is T3', () {
        expect(checkoutSuggestionForStrategy(9, 'master'), 'T3');
      });

      test('score 15 is T5', () {
        expect(checkoutSuggestionForStrategy(15, 'master'), 'T5');
      });

      test('score 50 is DB', () {
        expect(checkoutSuggestionForStrategy(50, 'master'), 'DB');
      });

      test('score 180 is T20 · T20 · T20', () {
        expect(
          checkoutSuggestionForStrategy(180, 'master'),
          'T20 · T20 · T20',
        );
      });

      test('returns null for score 1 (no master finish possible)', () {
        expect(checkoutSuggestionForStrategy(1, 'master'), isNull);
      });

      test('returns null for scores above 180', () {
        expect(checkoutSuggestionForStrategy(181, 'master'), isNull);
      });
    });
  });

  group('maxCheckoutScore', () {
    test('double out is 170', () {
      expect(maxCheckoutScore('double'), 170);
    });

    test('straight out is 180', () {
      expect(maxCheckoutScore('straight'), 180);
    });

    test('master out is 180', () {
      expect(maxCheckoutScore('master'), 180);
    });
  });

  group('minCheckoutScore', () {
    test('double out is 2', () {
      expect(minCheckoutScore('double'), 2);
    });

    test('straight out is 1', () {
      expect(minCheckoutScore('straight'), 1);
    });

    test('master out is 2', () {
      expect(minCheckoutScore('master'), 2);
    });
  });
}
