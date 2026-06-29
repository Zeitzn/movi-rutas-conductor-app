# Design: Profile Fetch Post-Login

## Technical Approach

Fail-hard profile fetch injected between `saveToken` and `emit(AuthAuthenticated)` in `_onLoginSubmitted`. Profile model mirrors `TokenResponse` exactly. Repository extends with same SharedPrefs + in-memory cache pattern. BLoC loads profile from repo on check/refresh (no re-fetch). EnvConfig adds one getter.

References spec: `openspec/specs/user-profile/spec.md` (R1–R7), `openspec/changes/profile-fetch-post-login/specs/env-config/spec.md` (R10).

## Architecture Decisions

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Fail-hard vs. soft-fail | Soft lets login succeed without profile, UI must handle missing data — but every authenticated screen needs profile | **Fail-hard**: if profile fetch fails, login fails. Simpler state, no null-check spread. |
| Profile in AuthService vs. new ProfilesService | New service is "cleaner" SRP but adds boilerplate and a new class | **AuthService**: single class, same HTTP client, same Error hierarchy. Profile fetch is an auth concern. |
| Token saved before profile fetch vs. only if profile succeeds | Saving first allows partial state (token in prefs, no profile). Clearing on fail adds complexity. | **Save token first** (per user BLoC pseudocode). If profile fails, token remains — checkAuthStatus on next app start loads it with profile=null. |
| Named vs. positional `profile` param in state | Positional breaks existing callers. | **Named optional**: `AuthAuthenticated(token, profile: null)` — backward-compatible with existing emits. |

## Data Flow

```
LoginSubmitted
    │
    ▼
AuthService.login() ──→ TokenResponse
    │
    ▼
saveToken(tokenWithUsername)
    │
    ▼
AuthService.fetchProfile(username, accessToken)
    │
    ├── 200 OK ──→ UserProfile.fromJson(json['data'])
    │                  │
    │                  ▼
    │              saveProfile(profile)
    │                  │
    │                  ▼
    │              emit(AuthAuthenticated(token, profile: profile))
    │
    └── error ──→ emit(AuthError(message))
                    (token already persisted — partial state)

CheckAuthStatus / RefreshTokenRequested
    │
    ▼
getToken() ──→ getProfile() ──→ emit(AuthAuthenticated(token, profile?))
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/features/auth/models/user_profile.dart` | **Create** | Equatable model: 6 fields, copyWith, toJson/fromJson (parses `data` envelope), props, toString |
| `lib/features/auth/services/auth_service.dart` | Modify | Add `fetchProfile()` — GET with Bearer auth, 10s timeout, parse `data` from response |
| `lib/features/auth/repositories/auth_repository.dart` | Modify | `IAuthRepository`: +3 methods. `SharedPrefsAuthRepository`: key `auth_profile`, in-memory cache, `clearProfile()` called inside `clearToken()` |
| `lib/features/auth/bloc/auth_state.dart` | Modify | `AuthAuthenticated` gains `UserProfile? profile` as named optional param (default null), included in `props` |
| `lib/features/auth/bloc/auth_bloc.dart` | Modify | 4 handlers: login→fetch+save profile; check/refresh→load from repo; logout→clear profile via clearToken; refresh preserves existing profile from repo |
| `lib/core/services/env_config.dart` | Modify | Add `profilesApiBaseUrl` getter reading `PROFILES_API_BASE_URL` from dotenv, fallback `http://localhost:8080` |
| `.env.example` | Modify | Add `# Profiles API\nPROFILES_API_BASE_URL=http://localhost:8080` |
| `assets/.env` | Modify | Add `PROFILES_API_BASE_URL=http://localhost:8080` |

## Interfaces / Contracts

```dart
// AuthService
Future<UserProfile> fetchProfile({
  required String username,
  required String accessToken,
});

// IAuthRepository
Future<void> saveProfile(UserProfile profile);
Future<UserProfile?> getProfile();
Future<void> clearProfile();

// AuthAuthenticated
const AuthAuthenticated(TokenResponse token, {UserProfile? profile});

// EnvConfig
String get profilesApiBaseUrl;
```

### API contract

```
GET {baseUrl}/api/profiles?username=USERNAME
Authorization: Bearer {accessToken}
Content-Type: application/json

Response 200:
  { "data": { "uuid": "...", "username": "ABC-333", "firstName": "...",
              "lastName": "...", "companyUuid": "...", "companyCode": "..." } }
```

### Dependencies between files

```
UserProfile ← (none, pure model)
AuthService         → EnvConfig, UserProfile, ServerFailure, NetworkFailure, http
SharedPrefsAuthRepository → UserProfile, SharedPreferences, jsonEncode/Decode
AuthBloc            → AuthService, IAuthRepository, TokenResponse, UserProfile
AuthState           → TokenResponse, UserProfile
EnvConfig           → flutter_dotenv
```

## Testing Strategy

| Layer | What | Approach |
|-------|------|----------|
| Unit | `UserProfile.fromJson` roundtrip | Same pattern as `route_point_test.dart`: construct → toJson → fromJson → expect equality |
| Unit | `UserProfile.fromJson` parsing `data` envelope | Test with full API response shape `{"data": {...}}` |
| — | AuthService, Repository, BLoC | **Skipped** — no mocking framework in project (`config.yaml`: `mocking: none`). Adding mockito is out of scope. |

## Migration / Rollout

No migration required. New profile storage key `auth_profile` is additive — existing users with saved tokens get `profile: null` on first load.

## Open Questions

- **Token saved but profile fetch fails**: on next app start, `checkAuthStatus` finds a valid token, loads profile from repo (null), emits `AuthAuthenticated` without profile. The user sees as authenticated with no profile — is this the intended UX? Alternative: clear token on profile fetch failure.
- The spec scenario R5 says "token is NOT stored" on fail-hard, but the BLoC design shows `saveToken()` BEFORE `fetchProfile()`. If the spec's behavior is preferred, the flow must reorder to: login → fetchProfile → saveProfile → saveToken → emit.
