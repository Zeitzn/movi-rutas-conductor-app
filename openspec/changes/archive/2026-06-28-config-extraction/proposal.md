# Proposal: Config Extraction

## Intent

Three hardcoded values prevent per-driver configuration, leak credentials in source, and block multi-device deployments. Extract them to dynamic configuration sources.

## Scope

### In Scope
- `driver_001` → real driver ID from authenticated user (`AuthBloc.token.username`)
- `numberPlate` → extract to SharedPreferences; source decided in design
- `authClientSecret` → move to `.env` via `flutter_dotenv`
- `EnvConfig` service: typed reader for `.env` + SharedPreferences
- Cross-isolate strategy: background isolate reads config from SharedPreferences

### Out of Scope
- PKCE migration for `client_secret` (requires Keycloak changes)
- Settings UI for `numberPlate` input

## Capabilities

### New Capabilities
- `env-config`: typed config loading from `.env` + SharedPreferences with fallback defaults

### Modified Capabilities
- None — STOMP format, route model, auth contract remain identical

## Approach

Three independent tracks (separable commits):

1. **`driver_001`** — `RouteTrackingPage` reads `authState.token.username` instead of literal
2. **`numberPlate`** — `WebSocketService` receives as constructor param; `BackgroundTrackingHandler` reads from SharedPreferences
3. **`authClientSecret`** — `flutter_dotenv`, `.env` + `.env.example`, `AuthService` reads from env

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `websocket_service.dart` | Modified | Constructor param for `numberPlate` |
| `route_tracking_page.dart` | Modified | `token.username` for `StartRoute` |
| `background_tracking_handler.dart` | Modified | Read `numberPlate` from prefs |
| `auth_service.dart` | Modified | Read `client_secret` from env |
| `app_constants.dart` | Modified | Remove `authClientSecret` |
| `lib/core/services/env_config.dart` | New | Typed config reader |
| `pubspec.yaml` | Modified | Add `flutter_dotenv` |
| `.env` / `.env.example` | New | Env file + template |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| SharedPrefs unavailable in background isolate | Low | Fallback via `sendDataToTask` |
| Env secret still extractable from APK | High | Document limitation; PKCE is real fix |
| `numberPlate` unset → broken STOMP msg | Low | Validate on route start |

## Rollback Plan

- Each track is a separable commit — revert individually
- `AppConstants` values kept as fallback defaults

## Dependencies

- `flutter_dotenv` (new)
- `shared_preferences` (already in pubspec)

## Success Criteria

- [ ] `driver_001` eliminated from source
- [ ] STOMP `numberPlate` from config, not hardcoded
- [ ] `authClientSecret` read from `.env`
- [ ] Background isolate sends correct `numberPlate` after task restart
- [ ] `fvm flutter analyze` passes with zero errors
