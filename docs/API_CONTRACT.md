# API Contract Specification

**Status:** Authoritative  
**Scope:** Backend API Interface  
**Version:** 1.0.0

---

## Executive Summary

### API Architecture Decision
- **Phase 1 (MVP):** REST API only for data synchronization
- **Phase 2 (Future):** WebSocket API for real-time multiplayer

### Core Principles
1. **Local-first**: All APIs are optional enhancements
2. **Event-based sync**: Upload events, not state snapshots
3. **Idempotent operations**: Safe to retry any request
4. **Stateless REST**: No session state on server (except auth tokens)
5. **JSON format**: All request/response bodies use JSON

### Base URLs
- **Development:** `http://localhost:8000`
- **Production:** `https://api.darts-app.com`
- **Self-hosted:** User configurable

### Authentication
- **Method:** JWT Bearer tokens
- **Token lifetime:** 15 minutes (access), 7 days (refresh)
- **Storage:** Secure platform-specific storage (Flutter Secure Storage)

### API Phases

| Phase | Scope | Status |
|-------|-------|--------|
| Phase 1 | REST API - Auth, Sync, Data | **Current Spec** |
| Phase 2 | WebSocket - Real-time Multiplayer | **Future Feature** |

---

## Phase 1: REST API (MVP)

### Authentication Endpoints

#### Register User

```http
POST /api/v1/auth/register
Content-Type: application/json
```

**Request:**
```json
{
  "email": "player@example.com",
  "password": "securePassword123",
  "name": "John Doe"
}
```

**Response: 201 Created**
```json
{
  "user_id": "usr_1a2b3c4d5e6f",
  "email": "player@example.com",
  "name": "John Doe",
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 900
}
```

**Error Responses:**
- `400 Bad Request` - Invalid email format or weak password
- `409 Conflict` - Email already registered

---

#### Login

```http
POST /api/v1/auth/login
Content-Type: application/json
```

**Request:**
```json
{
  "email": "player@example.com",
  "password": "securePassword123"
}
```

**Response: 200 OK**
```json
{
  "user_id": "usr_1a2b3c4d5e6f",
  "email": "player@example.com",
  "name": "John Doe",
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 900
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid credentials
- `429 Too Many Requests` - Rate limit exceeded (max 5 attempts per 15 minutes)

---

#### Refresh Token

```http
POST /api/v1/auth/refresh
Content-Type: application/json
```

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response: 200 OK**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 900
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or expired refresh token

---

#### Logout

```http
POST /api/v1/auth/logout
Authorization: Bearer {access_token}
```

**Response: 204 No Content**

---

### Player Endpoints

#### Get All Players

```http
GET /api/v1/players
Authorization: Bearer {access_token}
```

**Response: 200 OK**
```json
{
  "players": [
    {
      "player_id": "plr_a1b2c3d4",
      "name": "John Doe",
      "created_at": "2024-01-15T10:30:00Z",
      "last_active": "2024-02-08T14:20:00Z",
      "account_id": "usr_1a2b3c4d5e6f",
      "is_linked": true
    },
    {
      "player_id": "plr_e5f6g7h8",
      "name": "Jane Smith",
      "created_at": "2024-01-20T15:45:00Z",
      "last_active": "2024-02-07T18:30:00Z",
      "account_id": null,
      "is_linked": false
    }
  ]
}
```

---

#### Create Player

```http
POST /api/v1/players
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request:**
```json
{
  "player_id": "plr_client_generated_uuid",
  "name": "New Player"
}
```

**Response: 201 Created**
```json
{
  "player_id": "plr_client_generated_uuid",
  "name": "New Player",
  "created_at": "2024-02-08T15:00:00Z",
  "last_active": "2024-02-08T15:00:00Z",
  "account_id": "usr_1a2b3c4d5e6f",
  "is_linked": true
}
```

**Error Responses:**
- `400 Bad Request` - Invalid player data
- `409 Conflict` - Player ID already exists

---

#### Link Player to Account

```http
PUT /api/v1/players/{player_id}/link
Authorization: Bearer {access_token}
```

**Response: 200 OK**
```json
{
  "player_id": "plr_e5f6g7h8",
  "name": "Jane Smith",
  "account_id": "usr_1a2b3c4d5e6f",
  "is_linked": true,
  "linked_at": "2024-02-08T15:30:00Z"
}
```

**Error Responses:**
- `404 Not Found` - Player not found
- `409 Conflict` - Player already linked to another account

---

### Game Endpoints

#### Upload Completed Game

```http
POST /api/v1/games
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request:**
```json
{
  "game_id": "gme_9z8y7x6w5v4u",
  "game_type": "x01",
  "game_config": {
    "starting_score": 501,
    "in_strategy": "straight",
    "out_strategy": "double"
  },
  "competitors": [
    {
      "competitor_id": "cmp_1a2b3c",
      "type": "solo",
      "name": "John Doe",
      "player_ids": ["plr_a1b2c3d4"]
    },
    {
      "competitor_id": "cmp_4d5e6f",
      "type": "solo",
      "name": "Jane Smith",
      "player_ids": ["plr_e5f6g7h8"]
    }
  ],
  "events": [
    {
      "event_id": "evt_001",
      "event_type": "GameCreated",
      "game_id": "gme_9z8y7x6w5v4u",
      "occurred_at": "2024-02-08T14:00:00Z",
      "local_sequence": 0,
      "payload": {
        "ruleset": "X01",
        "rules": {
          "starting_score": 501,
          "out_strategy": "double"
        }
      }
    },
    {
      "event_id": "evt_002",
      "event_type": "TurnStarted",
      "game_id": "gme_9z8y7x6w5v4u",
      "occurred_at": "2024-02-08T14:00:05Z",
      "local_sequence": 1,
      "payload": {
        "competitor_id": "cmp_1a2b3c",
        "turn_index": 0
      }
    },
    {
      "event_id": "evt_003",
      "event_type": "DartThrown",
      "game_id": "gme_9z8y7x6w5v4u",
      "occurred_at": "2024-02-08T14:00:10Z",
      "local_sequence": 2,
      "payload": {
        "competitor_id": "cmp_1a2b3c",
        "segment": 20,
        "multiplier": 3,
        "input_method": "manual"
      }
    }
  ],
  "start_time": "2024-02-08T14:00:00Z",
  "end_time": "2024-02-08T14:45:00Z",
  "winner_competitor_id": "cmp_1a2b3c"
}
```

**Response: 201 Created**
```json
{
  "game_id": "gme_9z8y7x6w5v4u",
  "synced_at": "2024-02-08T15:00:00Z",
  "events_accepted": 47,
  "global_sequences": {
    "evt_001": 1001,
    "evt_002": 1002,
    "evt_003": 1003
  }
}
```

**Error Responses:**
- `400 Bad Request` - Invalid game data or events
- `409 Conflict` - Game ID already exists

---

#### Get User's Games

```http
GET /api/v1/games?limit=20&offset=0&player_id=plr_a1b2c3d4
Authorization: Bearer {access_token}
```

**Query Parameters:**
- `limit` (optional): Number of games to return (default: 20, max: 100)
- `offset` (optional): Pagination offset (default: 0)
- `player_id` (optional): Filter by player
- `game_type` (optional): Filter by game type (x01, cricket, around-the-clock)
- `start_date` (optional): Filter games after date (ISO 8601)
- `end_date` (optional): Filter games before date (ISO 8601)

**Response: 200 OK**
```json
{
  "games": [
    {
      "game_id": "gme_9z8y7x6w5v4u",
      "game_type": "x01",
      "start_time": "2024-02-08T14:00:00Z",
      "end_time": "2024-02-08T14:45:00Z",
      "winner_competitor_id": "cmp_1a2b3c",
      "competitors": [
        {
          "competitor_id": "cmp_1a2b3c",
          "name": "John Doe"
        },
        {
          "competitor_id": "cmp_4d5e6f",
          "name": "Jane Smith"
        }
      ]
    }
  ],
  "total": 156,
  "limit": 20,
  "offset": 0
}
```

---

#### Get Specific Game

```http
GET /api/v1/games/{game_id}
Authorization: Bearer {access_token}
```

**Response: 200 OK**
```json
{
  "game_id": "gme_9z8y7x6w5v4u",
  "game_type": "x01",
  "game_config": {
    "starting_score": 501,
    "out_strategy": "double"
  },
  "competitors": [
    {
      "competitor_id": "cmp_1a2b3c",
      "type": "solo",
      "name": "John Doe",
      "player_ids": ["plr_a1b2c3d4"]
    }
  ],
  "events": [
    // Full event stream
  ],
  "start_time": "2024-02-08T14:00:00Z",
  "end_time": "2024-02-08T14:45:00Z",
  "winner_competitor_id": "cmp_1a2b3c"
}
```

**Error Responses:**
- `404 Not Found` - Game not found or user doesn't have access

---

### Statistics Endpoints

#### Get Player Statistics

```http
GET /api/v1/statistics/player/{player_id}?game_type=x01
Authorization: Bearer {access_token}
```

**Query Parameters:**
- `game_type` (optional): Filter by game type
- `start_date` (optional): Stats from date onwards
- `end_date` (optional): Stats until date

**Response: 200 OK**
```json
{
  "player_id": "plr_a1b2c3d4",
  "game_type": "x01",
  "stats": {
    "total_games": 45,
    "games_won": 28,
    "win_rate": 0.622,
    "average_score": 68.5,
    "highest_checkout": 170,
    "three_dart_average": 72.3,
    "checkout_percentage": 0.35,
    "total_darts_thrown": 3456,
    "period_start": "2024-01-01T00:00:00Z",
    "period_end": "2024-02-08T23:59:59Z"
  }
}
```

---

#### Get Game Statistics

```http
GET /api/v1/statistics/game/{game_id}
Authorization: Bearer {access_token}
```

**Response: 200 OK**
```json
{
  "game_id": "gme_9z8y7x6w5v4u",
  "game_type": "x01",
  "player_stats": [
    {
      "player_id": "plr_a1b2c3d4",
      "player_name": "John Doe",
      "three_dart_average": 85.4,
      "checkout_percentage": 0.42,
      "highest_turn": 180,
      "darts_thrown": 72,
      "legs_won": 3
    },
    {
      "player_id": "plr_e5f6g7h8",
      "player_name": "Jane Smith",
      "three_dart_average": 78.2,
      "checkout_percentage": 0.38,
      "highest_turn": 140,
      "darts_thrown": 84,
      "legs_won": 2
    }
  ]
}
```

---

### Sync Endpoints

#### Get Events Since Sequence

```http
GET /api/v1/sync/events/{game_id}?since=1000
Authorization: Bearer {access_token}
```

**Query Parameters:**
- `since` (required): Global sequence number to fetch from

**Response: 200 OK**
```json
{
  "game_id": "gme_9z8y7x6w5v4u",
  "events": [
    {
      "event_id": "evt_042",
      "event_type": "DartThrown",
      "game_id": "gme_9z8y7x6w5v4u",
      "occurred_at": "2024-02-08T14:30:00Z",
      "local_sequence": 41,
      "global_sequence": 1042,
      "payload": {
        "competitor_id": "cmp_1a2b3c",
        "segment": 20,
        "multiplier": 1
      }
    }
  ],
  "latest_sequence": 1045
}
```

---

#### Upload Event Batch

```http
POST /api/v1/sync/events
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request:**
```json
{
  "game_id": "gme_9z8y7x6w5v4u",
  "events": [
    {
      "event_id": "evt_050",
      "event_type": "DartThrown",
      "game_id": "gme_9z8y7x6w5v4u",
      "occurred_at": "2024-02-08T14:35:00Z",
      "local_sequence": 49,
      "payload": {
        "competitor_id": "cmp_1a2b3c",
        "segment": 19,
        "multiplier": 3
      }
    }
  ]
}
```

**Response: 200 OK**
```json
{
  "accepted": 1,
  "rejected": 0,
  "global_sequences": {
    "evt_050": 1050
  }
}
```

---

### Error Response Format

All error responses follow this structure:

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "The request body is malformed",
    "details": {
      "field": "email",
      "reason": "Invalid email format"
    }
  },
  "request_id": "req_a1b2c3d4e5f6"
}
```

**Standard Error Codes:**
- `INVALID_REQUEST` - Malformed request
- `AUTHENTICATION_REQUIRED` - Missing or invalid auth token
- `FORBIDDEN` - Valid auth but insufficient permissions
- `NOT_FOUND` - Resource doesn't exist
- `CONFLICT` - Resource already exists
- `RATE_LIMITED` - Too many requests
- `SERVER_ERROR` - Internal server error
- `SERVICE_UNAVAILABLE` - Temporary service disruption

---

### Rate Limiting

**Limits:**
- Authentication endpoints: 5 requests per 15 minutes per IP
- Data endpoints: 100 requests per minute per user
- Upload endpoints: 20 requests per minute per user

**Headers:**
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1612814400
```

**Rate Limit Response: 429 Too Many Requests**
```json
{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Rate limit exceeded",
    "details": {
      "retry_after": 45
    }
  }
}
```

---

### Idempotency

**All POST/PUT requests support idempotency keys:**

```http
POST /api/v1/games
Authorization: Bearer {access_token}
Idempotency-Key: uuid-generated-by-client
Content-Type: application/json
```

- Same idempotency key within 24 hours returns cached response
- Prevents duplicate game uploads during retries
- Server stores key → response mapping for 24 hours

---

### Pagination

**Standard pagination pattern:**

```http
GET /api/v1/games?limit=20&offset=40
```

**Response includes:**
```json
{
  "data": [...],
  "total": 156,
  "limit": 20,
  "offset": 40,
  "has_more": true
}
```

---

## Phase 2: WebSocket API (Future Feature)

**Note:** This section defines the future real-time multiplayer API. It is not part of the MVP implementation.

### Connection

```
WSS /api/v1/multiplayer/ws?token={access_token}
```

### Message Format

All WebSocket messages use JSON:

```json
{
  "type": "message_type",
  "payload": { ... },
  "timestamp": "2024-02-08T15:00:00Z",
  "message_id": "msg_unique_id"
}
```

### Client → Server Messages

#### Create Session

```json
{
  "type": "create_session",
  "payload": {
    "game_type": "x01",
    "game_config": {
      "starting_score": 501,
      "out_strategy": "double"
    },
    "max_players": 4
  }
}
```

#### Join Session

```json
{
  "type": "join_session",
  "payload": {
    "session_id": "ses_a1b2c3d4",
    "player_id": "plr_e5f6g7h8"
  }
}
```

#### Submit Dart

```json
{
  "type": "dart_thrown",
  "payload": {
    "session_id": "ses_a1b2c3d4",
    "competitor_id": "cmp_1a2b3c",
    "segment": 20,
    "multiplier": 3
  }
}
```

### Server → Client Messages

#### Session Created

```json
{
  "type": "session_created",
  "payload": {
    "session_id": "ses_a1b2c3d4",
    "host_player_id": "plr_a1b2c3d4",
    "status": "waiting"
  }
}
```

#### Player Joined

```json
{
  "type": "player_joined",
  "payload": {
    "session_id": "ses_a1b2c3d4",
    "player_id": "plr_e5f6g7h8",
    "player_name": "Jane Smith"
  }
}
```

#### Game State Update

```json
{
  "type": "game_state",
  "payload": {
    "session_id": "ses_a1b2c3d4",
    "game_state": {
      "current_turn_index": 0,
      "darts_thrown_in_turn": 1,
      "competitors": [...]
    },
    "last_event": {
      "event_type": "DartThrown",
      "global_sequence": 1055
    }
  }
}
```

#### Error

```json
{
  "type": "error",
  "payload": {
    "code": "INVALID_TURN",
    "message": "Not your turn"
  }
}
```

**Future Implementation Notes:**
- Server validates all game events
- Server assigns global sequence numbers
- Server broadcasts confirmed events to all session participants
- Clients apply events locally for optimistic UI
- Reconnection protocol fetches missed events by sequence number

---

## API Versioning

**Strategy:** URL-based versioning

- Current: `/api/v1/...`
- Future: `/api/v2/...` (if breaking changes needed)

**Deprecation Policy:**
- Minimum 6 months notice before removing old version
- Sunset header on deprecated endpoints: `Sunset: Sat, 31 Aug 2024 23:59:59 GMT`

---

## Security Considerations

### HTTPS/TLS
- All production APIs must use HTTPS
- TLS 1.2 minimum
- Strong cipher suites only

### Authentication
- JWT tokens with short expiration
- Refresh tokens with rotation
- Tokens stored in secure storage (never in localStorage)

### Input Validation
- All inputs validated server-side
- SQL injection prevention
- XSS prevention in any text fields
- Max request size: 10MB

### Rate Limiting
- Per-IP limits for auth endpoints
- Per-user limits for data endpoints
- Exponential backoff recommended for clients

---

## Testing Endpoints

**Development only:**

```http
GET /api/v1/health
```

**Response: 200 OK**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2024-02-08T15:00:00Z"
}
```

---

## Client Implementation Guidelines

### Error Handling

```dart
try {
  final response = await dio.post('/api/v1/games', data: gameData);
  // Handle success
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    // Refresh token and retry
  } else if (e.response?.statusCode == 409) {
    // Game already exists - safe to ignore
  } else if (e.response?.statusCode == 429) {
    // Rate limited - exponential backoff
    final retryAfter = e.response?.headers['retry-after'];
    await Future.delayed(Duration(seconds: int.parse(retryAfter ?? '60')));
    // Retry
  } else {
    // Other error - show to user
  }
}
```

### Retry Logic

```dart
// Exponential backoff for retries
final delays = [1, 2, 4, 8, 16]; // seconds
for (final delay in delays) {
  try {
    return await apiCall();
  } catch (e) {
    if (delay == delays.last) rethrow;
    await Future.delayed(Duration(seconds: delay));
  }
}
```

### Offline Queue

```dart
// Queue uploads when offline
if (!isOnline) {
  await syncQueue.enqueue(gameData);
  return;
}

// Try to sync when online
try {
  await uploadGame(gameData);
  await syncQueue.markSynced(gameData.gameId);
} catch (e) {
  // Will retry later when network is back
}
```

---

## API Client Code Generation

**Recommended approach:**

1. Use OpenAPI/Swagger specification
2. Generate client code with `openapi-generator`
3. Maintain single source of truth for API contracts

**Example OpenAPI spec location:** `backend/openapi.yaml`

---

## Summary

### Phase 1 (MVP) - REST API
- ✅ Authentication (register, login, refresh, logout)
- ✅ Player management (CRUD, linking)
- ✅ Game upload (completed games with events)
- ✅ Game retrieval (list, single game)
- ✅ Statistics (player stats, game stats)
- ✅ Sync (event batching, sequence-based sync)

### Phase 2 (Future) - WebSocket API
- ⏳ Real-time multiplayer sessions
- ⏳ Live game state synchronization
- ⏳ Player presence and matchmaking

### Next Steps
1. Implement REST API backend
2. Implement REST API client in Flutter
3. Test offline-first sync workflow
4. Defer WebSocket implementation until user demand justifies it
