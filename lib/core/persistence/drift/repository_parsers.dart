// Shared parsers for drift row -> domain entity translation.
//
// These convert persisted column values (strings, ints) to typed enums. On
// unknown input every parser throws DatabaseException — a malformed row is
// a programming/data-integrity error, not something to paper over with a
// default. Previously each repo defined its own helper and two of them
// silently fell back to EventSource.values.first / GameType.x01, which
// would have masked corruption as a valid value (see issue #170).

import 'package:dart_lodge/core/error/repository_exception.dart';
import 'package:dart_lodge/core/utils/constants.dart';

GameType parseGameTypeFromColumn(String value) {
  return GameType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => throw DatabaseException(
      'Unknown game type in database: $value',
    ),
  );
}

EventSource parseEventSourceFromColumn(int value) {
  return EventSource.values.firstWhere(
    (source) => source.index == value,
    orElse: () => throw DatabaseException(
      'Unknown event source in database: $value',
    ),
  );
}

CompetitorType parseCompetitorTypeFromColumn(String value) {
  return CompetitorType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => throw DatabaseException(
      'Unknown competitor type in database: $value',
    ),
  );
}
