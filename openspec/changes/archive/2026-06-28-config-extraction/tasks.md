# Tasks: Config Extraction

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~140 (additions + deletions) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

## Phase 1: Foundation — EnvConfig Service

- [x] 1.1 Add `flutter_dotenv ^5.2.1` dependency to `pubspec.yaml`
- [x] 1.2 Add `.env` assets entry to `pubspec.yaml` (`assets/.env`)
- [x] 1.3 Create `.env` with `AUTH_CLIENT_SECRET=BWwkPsHgu4pcLhjEmqq4J775Tkp1hnKS`
- [x] 1.4 Create `.env.example` with `AUTH_CLIENT_SECRET=<keycloak-client-secret>`
- [x] 1.5 Create `lib/core/services/env_config.dart` — `EnvConfig` singleton with typed accessors (`authClientSecret`, `numberPlate`), init from `dotenv` + `SharedPreferences`, and PKCE caveat comment

## Phase 2: App Startup — EnvConfig Initialization

- [x] 2.1 In `main.dart`, call `EnvConfig.init()` after `WidgetsFlutterBinding.ensureInitialized()` and before `FlutterForegroundTask.init()`

## Phase 3: NumberPlate — WebSocket Constructor Parameter

- [x] 3.1 Add `numberPlate` as named constructor parameter to `WebSocketService`, store as field, use in `sendLocation()` replacing `'ABC-123'`
- [x] 3.2 Update `BackgroundTrackingHandler` — add `String? _numberPlate` field; parse `onReceiveData` for `{'type': 'config', 'numberPlate': 'X'}`; pass to `WebSocketService` constructor in `onStart`
- [x] 3.3 Update `RouteTrackingBloc._onStartRoute` — after `startService()`, call `sendDataToTask({'type': 'config', 'numberPlate': numberPlate})` reading from `EnvConfig.numberPlate`
- [x] 3.4 Fix `callbackDispatcher` in `main.dart` — pass numberPlate to `WebSocketService()` constructor

## Phase 4: DriverId — Authenticated User

- [x] 4.1 In `RouteTrackingPage._startNewRoute`, read `authState.token.username` with fallback `'unknown'` instead of hardcoded `'driver_001'`

## Phase 5: AuthClientSecret — EnvConfig Wiring

- [x] 5.1 In `AuthService.login()` and `refreshToken()`, replace `AppConstants.authClientSecret` with `EnvConfig.instance.authClientSecret`

## Phase 6: Cleanup

- [x] 6.1 Remove `authClientSecret` constant from `AppConstants`
- [x] 6.2 Run `fvm flutter analyze` and fix any issues
