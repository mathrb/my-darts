import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/persistence/drift/repository_parsers.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';

void main() {
  group('parseGameTypeFromColumn', () {
    test('returns the enum for every known game type', () {
      for (final type in GameType.values) {
        expect(parseGameTypeFromColumn(type.name), type);
      }
    });

    test('throws DatabaseException on unknown game type', () {
      expect(
        () => parseGameTypeFromColumn('nope'),
        throwsA(isA<DatabaseException>().having(
          (e) => e.message,
          'message',
          contains('Unknown game type'),
        )),
      );
    });

    test('throws DatabaseException on empty string', () {
      expect(
        () => parseGameTypeFromColumn(''),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('parseEventSourceFromColumn', () {
    test('returns the enum for every known event source index', () {
      for (final source in EventSource.values) {
        expect(parseEventSourceFromColumn(source.index), source);
      }
    });

    test('throws DatabaseException on out-of-range index', () {
      expect(
        () => parseEventSourceFromColumn(999),
        throwsA(isA<DatabaseException>().having(
          (e) => e.message,
          'message',
          contains('Unknown event source'),
        )),
      );
    });

    test('throws DatabaseException on negative index', () {
      expect(
        () => parseEventSourceFromColumn(-1),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
