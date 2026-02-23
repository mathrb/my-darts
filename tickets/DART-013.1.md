## DART-013.1 — Database initialization (onCreate) fails for new users due to migration redundancy

**Type:** Bug / Infrastructure  
**Component:** `lib/core/persistence/database_migrations.dart`, `lib/core/persistence/database_helper.dart`

### Description

The current database initialization flow is broken for new installations (empty database).

1. `DatabaseHelper._createDB` calls `DatabaseMigrations.createFullMigrationScript(db)`.
2. `createFullMigrationScript` calls `createVersion1(db)`, then `createVersion2Migration(db)`, then `createVersion2(db)`.
3. `createVersion1(db)` has been updated to include columns and indexes from later versions (e.g., `actor_id` from v2, `idx_games_single_active` from v3).
4. `createVersion2Migration(db)` attempts to `ALTER TABLE game_events ADD COLUMN actor_id ...`.
5. This `ALTER TABLE` statement fails because the column already exists in the table created by `createVersion1`.

As a result, any new user attempting to start the app will encounter a database error immediately upon initialization.

### Required changes

Refactor the migration logic to follow standard `sqflite` patterns:
1. `createVersion1` should be a snapshot of the LATEST authoritative schema (all tables, columns, and indexes as they should exist today).
2. `createFullMigrationScript` (or a better-named `createLatestSchema`) should only call the methods necessary to build the LATEST schema from scratch without attempting to run incremental `ALTER TABLE` migrations.
3. `DatabaseHelper._upgradeDB` remains responsible for the incremental path (v1 -> v2, v2 -> v3, etc.) for existing users who already have an older database.

### Acceptance criteria

- [ ] New installations (empty database) initialize successfully without SQL errors
- [ ] All tables (`players`, `games`, `competitors`, `competitor_players`, `dart_throws`, `game_events`, `accounts`, `sync_queue`, `game_sessions`) are created
- [ ] All indexes (including `idx_games_single_active`) are present in new installations
- [ ] Incremental migrations still work for existing users
