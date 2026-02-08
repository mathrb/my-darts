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
- **Method:** JWT Bearer tokens (email/password)
- **Token lifetime:** 15 minutes (access), 7 days (refresh)
- **Storage:** Secure platform-specific storage (Flutter Secure Storage)
- **Future:** OAuth providers (Google, Apple) may be added based on user demand

### API Phases

| Phase | Scope | Status |
|-------|-------|--------|
| Phase 1 | REST API - Custom Auth, Sync, Data | **Current Spec** |
| Phase 2 | OAuth Providers (Optional Enhancement) | **Future Feature** |
| Phase 3 | WebSocket - Real-time Multiplayer | **Future Feature** |

---

## Authentication Architecture

### Current Implementation: Custom Auth (Email/Password)

This API currently implements JWT-based email/password authentication. This approach provides:
- ✅ **Simple setup** - No external dependencies
- ✅ **Self-hosting friendly** - Works on any server
- ✅ **Full control** - Complete control over auth flow
- ✅ **Privacy** - No third-party tracking

### Future Extensibility: OAuth Providers

OAuth providers (Google, Apple, etc.) may be added in the future without breaking changes. When implemented:
- Both authentication methods will coexist
- Existing users continue using email/password
- New users can choose their preferred method
- Backend will auto-detect token type
- No migration required for existing accounts

**Database ready:** User schema uses nullable password field to accommodate future OAuth users.

**Token format:** Backend inspects token claims to determine type (custom JWT vs OAuth).

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

**Password Requirements:**
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character recommended

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

## Future Features (Not in MVP)

### Phase 2: OAuth Authentication (Optional Enhancement)

**Note:** OAuth providers will be added based on user demand. When implemented, the following capabilities will be available.

**Supported Providers:**
- Google Sign-In
- Apple Sign-In
- (Others may be added)

**Integration Approach:**

OAuth will coexist with custom auth:
- Users can choose their preferred sign-in method
- Backend auto-detects token type by inspecting claims
- No breaking changes to existing API
- Same authorization header format: `Authorization: Bearer {token}`

**Detection Endpoint:**
```http
GET /api/v1/auth/capabilities
```

**Response:**
```json
{
  "auth_methods": ["custom"],
  "oauth_providers": [],
  "custom_auth_enabled": true,
  "anonymous_allowed": true
}
```

When OAuth is enabled, response will include:
```json
{
  "auth_methods": ["custom", "oauth"],
  "oauth_providers": ["google", "apple"],
  "custom_auth_enabled": true,
  "anonymous_allowed": true
}
```

**Client Implementation:**
1. Check capabilities endpoint to see what's supported
2. Present appropriate sign-in options to user
3. For OAuth: Use provider's SDK to get token
4. Send token in Authorization header (same format as custom auth)
5. Backend validates with appropriate provider

---

### Phase 3: WebSocket API (Real-Time Multiplayer)

**Note:** Real-time multiplayer is a planned future feature for remote play. It is not part of the MVP implementation.

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
- SQL injection prevention (use parameterized queries)
- XSS prevention in any text fields
- Max request size: 10MB

**Password Storage:**
- Use bcrypt or Argon2 for password hashing
- Minimum cost factor: 12 for bcrypt
- Store salt with hash
- Password field nullable in database (for future OAuth users)

**Token Generation:**
- Use cryptographically secure random for JWT secrets
- Minimum 256-bit secret key
- Sign tokens with HS256 or RS256
- Include expiration in all tokens

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

### Authentication Flow

```dart
// Login with email/password
class AuthService {
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  Future<User> login(String email, String password) async {
    final response = await dio.post(
      '/api/v1/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final accessToken = response.data['access_token'];
    final refreshToken = response.data['refresh_token'];

    // Store tokens securely
    await secureStorage.write(key: 'access_token', value: accessToken);
    await secureStorage.write(key: 'refresh_token', value: refreshToken);

    return User.fromJson(response.data);
  }

  Future<void> logout() async {
    final token = await secureStorage.read(key: 'access_token');
    
    await dio.post(
      '/api/v1/auth/logout',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    // Clear stored tokens
    await secureStorage.delete(key: 'access_token');
    await secureStorage.delete(key: 'refresh_token');
  }

  // Add authenticated requests interceptor
  void setupInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await secureStorage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Auto-refresh on 401
        if (error.response?.statusCode == 401) {
          final newToken = await refreshAccessToken();
          if (newToken != null) {
            // Retry original request with new token
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newToken';
            final response = await dio.fetch(opts);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<String?> refreshAccessToken() async {
    final refreshToken = await secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) return null;

    try {
      final response = await dio.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'];
      final newRefreshToken = response.data['refresh_token'];

      await secureStorage.write(key: 'access_token', value: newAccessToken);
      await secureStorage.write(key: 'refresh_token', value: newRefreshToken);

      return newAccessToken;
    } catch (e) {
      // Refresh failed - user needs to login again
      await logout();
      return null;
    }
  }
}
```

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

## Backend Implementation Guidelines

### Custom Authentication Implementation

**Recommended Libraries:**
- **Python:** `passlib` (password hashing), `PyJWT` (token generation)
- **Node.js:** `bcrypt`, `jsonwebtoken`
- **Rust:** `argon2`, `jsonwebtoken`

**Example Implementation (Python/FastAPI):**

```python
from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT configuration
SECRET_KEY = "your-secret-key-min-256-bits"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 15
REFRESH_TOKEN_EXPIRE_DAYS = 7

security = HTTPBearer()

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(user_id: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode = {
        "sub": user_id,
        "exp": expire,
        "iss": "darts-app-backend",
        "type": "access"
    }
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def create_refresh_token(user_id: str) -> str:
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode = {
        "sub": user_id,
        "exp": expire,
        "iss": "darts-app-backend",
        "type": "refresh"
    }
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """Verify JWT token and return user_id"""
    token = credentials.credentials
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

@app.post("/api/v1/auth/register")
async def register(email: str, password: str, name: str):
    # Validate password strength
    if len(password) < 8:
        raise HTTPException(status_code=400, detail="Password too short")
    
    # Check if user exists
    if await user_exists(email):
        raise HTTPException(status_code=409, detail="Email already registered")
    
    # Create user
    user_id = str(uuid4())
    hashed_password = hash_password(password)
    
    await db.create_user(
        user_id=user_id,
        email=email,
        password_hash=hashed_password,
        name=name
    )
    
    # Generate tokens
    access_token = create_access_token(user_id)
    refresh_token = create_refresh_token(user_id)
    
    return {
        "user_id": user_id,
        "email": email,
        "name": name,
        "access_token": access_token,
        "refresh_token": refresh_token,
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }

@app.post("/api/v1/auth/login")
async def login(email: str, password: str):
    # Get user
    user = await db.get_user_by_email(email)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Verify password
    if not verify_password(password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Generate tokens
    access_token = create_access_token(user.user_id)
    refresh_token = create_refresh_token(user.user_id)
    
    return {
        "user_id": user.user_id,
        "email": user.email,
        "name": user.name,
        "access_token": access_token,
        "refresh_token": refresh_token,
        "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }

@app.post("/api/v1/auth/refresh")
async def refresh(refresh_token: str):
    try:
        payload = jwt.decode(refresh_token, SECRET_KEY, algorithms=[ALGORITHM])
        
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        
        user_id = payload.get("sub")
        
        # Generate new tokens
        new_access_token = create_access_token(user_id)
        new_refresh_token = create_refresh_token(user_id)
        
        return {
            "access_token": new_access_token,
            "refresh_token": new_refresh_token,
            "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60
        }
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

# Protect routes with token verification
@app.get("/api/v1/games")
async def get_games(user_id: str = Depends(verify_token)):
    games = await db.get_user_games(user_id)
    return {"games": games}
```

**Future OAuth Extension:**

When adding OAuth, the `verify_token` function becomes:

```python
async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    token = credentials.credentials
    
    # Try custom JWT
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("iss") == "darts-app-backend":
            return payload.get("sub")
    except JWTError:
        pass
    
    # Try Firebase (when OAuth is added)
    try:
        from firebase_admin import auth
        decoded = auth.verify_id_token(token)
        user_id = decoded['uid']
        
        # Get or create user from OAuth
        user = await db.get_or_create_oauth_user(user_id, decoded)
        return user.user_id
    except:
        pass
    
    raise HTTPException(status_code=401, detail="Invalid token")
```

**Note:** Only 15 lines need to be added to support OAuth later.

---

## API Client Code Generation

**Recommended approach:**

1. Use OpenAPI/Swagger specification
2. Generate client code with `openapi-generator`
3. Maintain single source of truth for API contracts

**Example OpenAPI spec location:** `backend/openapi.yaml`

---

## Summary

### Phase 1 (MVP) - REST API ✅
- ✅ **Custom Authentication** (email/password register, login, refresh, logout)
- ✅ **Player management** (CRUD, linking to accounts)
- ✅ **Game upload** (completed games with events)
- ✅ **Game retrieval** (list, single game with filters)
- ✅ **Statistics** (player stats, game stats, projections)
- ✅ **Sync** (event batching, sequence-based sync)
- ✅ **Anonymous mode** (local-only play without account)

### Phase 2 (Future) - OAuth Enhancement
- ⏳ Google Sign-In integration
- ⏳ Apple Sign-In integration
- ⏳ Multi-provider support
- ⏳ Coexistence with custom auth

### Phase 3 (Future) - WebSocket API
- ⏳ Real-time multiplayer sessions
- ⏳ Live game state synchronization
- ⏳ Player presence and matchmaking

### Next Steps
1. Implement REST API backend with custom auth
2. Implement REST API client in Flutter
3. Test offline-first sync workflow
4. Gather user feedback on auth preferences
5. Add OAuth if users request it (1-2 days of work)
6. Defer WebSocket implementation until user demand justifies it

