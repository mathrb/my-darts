import '../models/game_state.dart';
import '../../../../core/error/repository_exception.dart';

/// Returns the player ID for the competitor currently throwing.
/// Throws [InvalidGameStateException] if the competitor is not found.
/// Returns 'system' if the competitor has no players.
String getCurrentPlayerId(GameState state, String competitorId) {
  final competitor = state.competitors.firstWhere(
    (c) => c.competitorId == competitorId,
    orElse: () => throw const InvalidGameStateException('Competitor not found'),
  );
  return competitor.playerIds.isNotEmpty ? competitor.playerIds.first : 'system';
}

/// Returns the player ID for the given competitor ID, or '' if null/not found.
/// Used for optional winner/context payloads where a missing ID is non-fatal.
String getPlayerIdForCompetitor(GameState state, String? competitorId) {
  if (competitorId == null) return '';
  final matches = state.competitors.where((c) => c.competitorId == competitorId);
  if (matches.isEmpty) return '';
  final competitor = matches.first;
  return competitor.playerIds.isNotEmpty ? competitor.playerIds.first : '';
}
