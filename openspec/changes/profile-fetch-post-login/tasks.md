# Tasks: Profile Fetch Post-Login

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~240 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

## Phase 1: Foundation

- [ ] 1.1 Create `lib/features/auth/models/user_profile.dart` — Equatable with 6 fields, copyWith, toJson/fromJson (parses `data` envelope), props, toString
- [ ] 1.2 Add `String get profilesApiBaseUrl` to `EnvConfig` — reads `PROFILES_API_BASE_URL` from dotenv, fallback `http://localhost:8080`

## Phase 2: Service + Repository

- [ ] 2.1 Add `Future<UserProfile> fetchProfile({required String username, required String accessToken})` to `AuthService` — GET with Bearer auth, 10s timeout, parse `data`, non-200 → `ServerFailure`
- [ ] 2.2 Extend `IAuthRepository` with `saveProfile`, `getProfile`, `clearProfile`; implement in `SharedPrefsAuthRepository` with key `auth_profile`, JSON cache, and `clearProfile()` inside `clearToken()`

## Phase 3: BLoC Wiring

- [ ] 3.1 Add `UserProfile? profile` as named optional param to `AuthAuthenticated` const constructor; include in `props`
- [ ] 3.2 `_onLoginSubmitted`: reorder to login → fetchProfile → saveToken + saveProfile → emit AuthAuthenticated(profile). Fetch failure → emit AuthError (no persist).
- [ ] 3.3 `_onCheckAuthStatus`: after token check, load profile from repo. If token exists but profile is null → clear orphan token, emit AuthUnauthenticated.
- [ ] 3.4 `_onRefreshTokenRequested`: load profile from repo, emit with existing profile or null.

## Phase 4: Tests + Config

- [ ] 4.1 Write `test/features/auth/models/user_profile_test.dart` — 2 tests: roundtrip toJson/fromJson, Equatable equality
- [ ] 4.2 Add `PROFILES_API_BASE_URL=http://localhost:8080` to `.env.example` and `assets/.env`
- [ ] 4.3 Verify: `fvm flutter analyze` + `fvm flutter test` pass
