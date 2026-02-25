# Database Layer — Review Tickets

Tickets generated from a review of `lib/core/persistence/` against `DATABASE_DDL.md`, `REPOSITORY_INTERFACES.md`, and `DATA.md`.

**Tackle in order.** DB-001 is a prerequisite — several issues in later tickets are caused by or live inside the versioned migration code that DB-001 removes.

---

## DB-001 — Collapse all versioned migrations into a single baseline schema

**Priority:** High  
**Files:**
- `lib/core/persistence/database_migrations.dart`
- `lib/core/persistence/database_helper.dart`
- `lib/core/persistence/drift/database.dart`

### Background

The app has not been released. No user devices exist with an older schema version. The current migration infrastructure carries three versioned upgrade paths (v1 → v2 → v3) that add complexity, contain bugs, and provide no practical value at this stage.

### What to Do

**`database_migrations.dart`**

Delete `createVersion1()`, `createVersion2Migration()`, `createVersion2()`, and `createVersion3()` entirely. Keep only `createLatestSchema()`, renamed to `createSchema()` for clarity, which must represent the complete final schema in a single pass. Before merging, audit it against `DATABASE_DDL.md` — specifically, the `account_id` column on `players` is currently missing its `REFERENCES accounts(account_id) ON DELETE SET NULL` clause and must be corrected:

```dart
// Correct players table CREATE statement:
await db.execute('''
  CREATE TABLE players (
    player_id   TEXT NOT NULL PRIMARY KEY,
    name        TEXT NOT NULL,
    created_at  TEXT NOT NULL,
    last_active TEXT NOT NULL,
    account_id  TEXT REFERENCES accounts(account_id) ON DELETE SET NULL,
    avatar_url  TEXT
  );
''');
```

**`database_helper.dart`**

Set `DatabaseConstants.databaseVersion` to `1`. Simplify `_initDB` to only use `onCreate`; remove `onUpgrade`:

```dart
return await sqflite.openDatabase(
  fullPath,
  version: 1,
  onCreate: (db, version) async {
    await DatabaseMigrations.createSchema(db);
  },
  onOpen: (db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  },
);
```

**`drift/database.dart`**

Remove the `onUpgrade` handler entirely. `onCreate` should call `m.createAll()` and then create the `idx_games_single_active` partial index via `customStatement`, since Drift's table DSL cannot express partial indexes:

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await m.database.customStatement(
        'CREATE UNIQUE INDEX idx_games_single_active ON games(is_complete) WHERE is_complete = 0;',
      );
    },
  );
}
```

### Definition of Done

- [ ] `createVersion1`, `createVersion2Migration`, `createVersion2`, `createVersion3` are deleted
- [ ] `createSchema()` matches `DATABASE_DDL.md` exactly, including the `account_id` foreign key reference on `players`
- [ ] `DatabaseConstants.databaseVersion` is `1`
- [ ] `onUpgrade` is removed from `DatabaseHelper`
- [ ] Drift `onUpgrade` handler is removed
- [ ] Drift `onCreate` creates all tables plus the `idx_games_single_active` partial index via `customStatement`

---

## DB-002 — Drift table classes are missing foreign key declarations

**Priority:** High  
**File:** `lib/core/persistence/drift/database.dart`  
**Depends on:** DB-001

### Problem

The Drift table classes (`Competitors`, `CompetitorPlayers`, `DartThrows`, `GameEvents`, `GameSessions`) do not declare their foreign key relationships. Drift requires these to be expressed via the `.references()` column builder method for them to be emitted in the generated `CREATE TABLE` SQL.

As a result, the web schema has no `REFERENCES` clauses and no `ON DELETE CASCADE / RESTRICT / SET NULL` semantics — all foreign key integrity specified in `DATABASE_DDL.md` is silently absent on the web platform.

### Fix

Add `.references()` to every foreign key column. Use the `onDelete` parameter to match the spec. Example for `Competitors`:

```dart
class Competitors extends Table {
  TextColumn get competitorId => text()();
  TextColumn get gameId => text().references(Games, #gameId, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {competitorId};
}
```

Apply the same pattern across all tables, matching the `ON DELETE` action from `DATABASE_DDL.md`:

| Table | Column | References | On Delete |
|---|---|---|---|
| `Competitors` | `gameId` | `Games.gameId` | CASCADE |
| `CompetitorPlayers` | `competitorId` | `Competitors.competitorId` | CASCADE |
| `CompetitorPlayers` | `playerId` | `Players.playerId` | RESTRICT |
| `DartThrows` | `gameId` | `Games.gameId` | CASCADE |
| `DartThrows` | `competitorId` | `Competitors.competitorId` | CASCADE |
| `DartThrows` | `playerId` | `Players.playerId` | RESTRICT |
| `GameEvents` | `gameId` | `Games.gameId` | CASCADE |
| `GameSessions` | `gameId` | `Games.gameId` | CASCADE |
| `GameSessions` | `hostPlayerId` | `Players.playerId` | RESTRICT |
| `GameSessions` | `currentTurnPlayerId` | `Players.playerId` | SET NULL |
| `Players` | `accountId` | `Accounts.accountId` | SET NULL |

---

## DB-003 — `getDatabasesPath()` shadows sqflite's built-in path resolver

**Priority:** Medium  
**File:** `lib/core/persistence/database_helper.dart`  
**Depends on:** DB-001

### Problem

A top-level `getDatabasesPath()` function is defined at the bottom of `database_helper.dart` and shadows the sqflite package's own function of the same name:

```dart
Future<String> getDatabasesPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}
```

sqflite's `getDatabasesPath()` returns the platform-appropriate databases directory (e.g. `/data/data/<package>/databases` on Android). Using the documents directory deviates from the platform convention and may cause issues with backup exclusion and file access permissions on some Android versions.

### Fix

Remove the custom function entirely. In `_initDB`, call sqflite's version directly via the package alias:

```dart
final dbPath = await sqflite.getDatabasesPath();
```

---

## DB-004 — `getCompetitors()` does not populate player rosters

**Priority:** Medium  
**File:** `lib/core/persistence/drift/repositories/game_repository_drift.dart`

### Problem

`REPOSITORY_INTERFACES.md` specifies that `getCompetitors(gameId)` returns each competitor **with their full player roster**. The current implementation hardcodes an empty list:

```dart
return results.map((row) => Competitor(
  ...
  players: [], // Empty list for now
)).toList();
```

This breaks `ProcessDartUseCase`, game display, and any statistics that need to know which players belong to a competitor.

### Fix

Join `competitor_players` and `players` in a single query, then group by `competitor_id` to build the nested structure:

```dart
final rows = await (_db.select(_db.competitors)
  ..where((c) => c.gameId.equals(gameId)))
  .join([
    leftOuterJoin(
      _db.competitorPlayers,
      _db.competitorPlayers.competitorId.equalsExp(_db.competitors.competitorId),
    ),
    leftOuterJoin(
      _db.players,
      _db.players.playerId.equalsExp(_db.competitorPlayers.playerId),
    ),
  ])
  .get();

// Group rows by competitor_id, collect players per competitor
```

---

## DB-005 — `watch*` methods use polling or one-shot futures instead of reactive Drift streams

**Priority:** Medium  
**Files:**
- `lib/core/persistence/drift/repositories/player_repository_drift.dart`
- `lib/core/persistence/drift/repositories/game_repository_drift.dart`
- `lib/core/persistence/drift/repositories/game_event_repository_drift.dart`

### Problem

`REPOSITORY_INTERFACES.md` specifies that `watch*` methods must emit whenever the underlying data changes. The current implementations either emit once and complete (`Stream.fromFuture`) or poll on a fixed 1-second timer (`Stream.periodic`):

```dart
// Fires once, not reactive:
Stream<List<Player>> watchAllPlayers() => Stream.fromFuture(getAllPlayers());

// Polls every second — wasteful and introduces lag:
Stream<Game?> watchActiveGame() {
  return Stream.periodic(const Duration(seconds: 1), (_) async {
    return await getActiveGame();
  }).asyncMap((f) => f);
}
```

### Fix

Use Drift's built-in `.watch()` on select statements. Drift tracks which tables a query touches and re-emits automatically on writes:

```dart
@override
Stream<List<Player>> watchAllPlayers() {
  return (_db.select(_db.players)
    ..orderBy([(t) => OrderingTerm(expression: t.lastActive, mode: OrderingMode.desc)]))
    .watch()
    .map((rows) => rows.map((row) => Player(
          playerId: row.playerId,
          name: row.name,
          createdAt: DateTime.parse(row.createdAt),
          lastActive: DateTime.parse(row.lastActive),
        )).toList());
}
```

Apply the same pattern to `watchActiveGame()`, `watchCompletedGames()`, and `watchEventsForGame()`.

---

## DB-006 — `StatisticsRepositoryDrift.getPlayerStats()` adds duplicate joins when multiple filters are active

**Priority:** Medium  
**File:** `lib/core/persistence/drift/repositories/statistics_repository_drift.dart`

### Problem

When `gameType`, `from`, and `to` are all provided, `getPlayerStats()` calls `.join()` on the same Drift query builder three times. Each call appends another join clause to the same query, producing invalid SQL with duplicate table references:

```dart
if (gameType != null) {
  dartCountQuery.join([innerJoin(_db.games, ...)]);
}
if (from != null) {
  dartCountQuery.join([innerJoin(_db.games, ...)]); // duplicate
}
if (to != null) {
  dartCountQuery.join([innerJoin(_db.games, ...)]); // duplicate
}
```

### Fix

Add the join once, then apply all applicable `where` clauses:

```dart
if (gameType != null || from != null || to != null) {
  dartCountQuery.join([
    innerJoin(_db.games, _db.games.gameId.equalsExp(_db.dartThrows.gameId)),
  ]);
  if (gameType != null) {
    dartCountQuery.where(_db.games.gameType.equals(gameType.name));
  }
  if (from != null) {
    dartCountQuery.where(_db.games.startTime.isBiggerOrEqualValue(from.toIso8601String()));
  }
  if (to != null) {
    dartCountQuery.where(_db.games.startTime.isSmallerOrEqualValue(to.toIso8601String()));
  }
}
```

Apply the same fix to the `avgScoreQuery` block in the same method.

---

## DB-007 — `StatisticsRepositoryDrift` returns hardcoded placeholder values

**Priority:** Medium  
**File:** `lib/core/persistence/drift/repositories/statistics_repository_drift.dart`

### Problem

Key fields in `getPlayerStats()`, `getPlayerStatsForGame()`, and `getGameStats()` are hardcoded stubs and will never return real data:

```dart
return PlayerStats(
  totalGames: 1,        // Placeholder
  gamesWon: 0,          // Placeholder
  winRate: 0.0,         // Placeholder
  highestTurnScore: 0,  // Placeholder
  bustRate: 0.0,        // Placeholder
  dartsPerLeg: dartCount > 0 ? dartCount / 1.0 : 0.0, // always equals dartCount
  ...
);
```

`getGameStats()` returns an empty `byCompetitor: []` list, making it useless for any in-game stats display.

### Fix

Implement the required aggregation queries. At minimum, the following must be derived from real data:

- **`totalGames`** — count of distinct `game_id` values in `dart_throws` joined to `games` where `is_complete = 1` and `player_id` matches.
- **`gamesWon`** — count of completed games where `winner_competitor_id` belongs to a competitor that contains the player.
- **`winRate`** — `gamesWon / totalGames`, guarded against division by zero.
- **`highestTurnScore`** — `MAX` of per-turn score sums (`GROUP BY game_id, turn_number`).
- **`byCompetitor` in `GameStats`** — group `dart_throws` by `competitor_id` for the given game and compute per-competitor aggregates.

Fields such as `checkoutPercentage`, `bustRate`, and `highestCheckout` require game-type-specific logic and may be deferred to a follow-up ticket, but must not silently return `0` or `null` without a comment explaining why.

