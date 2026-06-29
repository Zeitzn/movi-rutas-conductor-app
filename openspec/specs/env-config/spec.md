# EnvConfig Specification

## Purpose

Centralized typed configuration service that loads dynamic config from `.env` (via `flutter_dotenv`) and `SharedPreferences`, replacing hardcoded values in `AppConstants`. MUST be available in both the main isolate and the background foreground task isolate.

## Requirements

### R1: EnvConfig MUST load `.env` at app startup

The service MUST call `dotenv.load()` before any config accessor is used. Loading MUST happen in `main()` before `runApp()`.

#### Scenario: Load success

- GIVEN a valid `.env` file in the project root
- WHEN `EnvConfig.init()` is called
- THEN all env vars are available via typed accessors

#### Scenario: Missing `.env` file

- GIVEN no `.env` file exists
- WHEN `EnvConfig.init()` is called
- THEN fallback defaults are used for every key
- AND no crash occurs

### R2: EnvConfig MUST expose typed accessors

Each config value SHALL have a dedicated typed getter: `String`, `int`, `bool`. Generic `getString(key)`/`getInt(key)` SHOULD be available for future keys.

#### Scenario: String accessor returns correct value

- GIVEN `EnvConfig` is initialized
- WHEN `authClientSecret` is accessed via the typed getter
- THEN it returns the value from `.env`
- AND falls back to `''` if not set

#### Scenario: Missing key falls back to default

- GIVEN a key not present in `.env` or `SharedPreferences`
- WHEN accessed via typed getter
- THEN the configured default value is returned
- AND no exception is thrown

### R3: EnvConfig MUST provide `numberPlate` backed by SharedPreferences

The `numberPlate` MUST be readable via `EnvConfig.numberPlate` which reads from `SharedPreferences`. Default value SHALL be `''`.

#### Scenario: numberPlate configured in prefs

- GIVEN `numberPlate` is saved in `SharedPreferences`
- WHEN `EnvConfig.numberPlate` is accessed
- THEN it returns the stored value

#### Scenario: numberPlate not configured

- GIVEN `SharedPreferences` has no `numberPlate` key
- WHEN `EnvConfig.numberPlate` is accessed
- THEN it returns `''`

### R4: EnvConfig SHALL be accessible from both isolates

The main isolate SHALL initialize `EnvConfig` at startup. The background isolate MUST NOT call `dotenv.load()` again — it SHALL read `SharedPreferences` (isolate-safe in Flutter) or receive values via `sendDataToTask`.

#### Scenario: Background isolate reads numberPlate

- GIVEN the foreground task starts
- WHEN `BackgroundTrackingHandler.onStart()` executes
- THEN `EnvConfig.numberPlate` returns the same value as the main isolate
- AND no separate `dotenv.load()` is needed

### R5: EnvConfig SHALL document authClientSecret limitation

The `authClientSecret` accessor MUST include a doc comment noting this is a public client secret and PKCE is the proper solution for mobile apps. It MUST NOT be re-exported or logged.

#### Scenario: PKCE caveat documented

- GIVEN the `authClientSecret` getter definition
- WHEN inspected
- THEN it contains a documentation comment explaining PKCE is the real fix
- AND the value is never printed or exposed in logs

### R6: RouteTrackingPage MUST pass authenticated driver ID

The page MUST read `AuthAuthenticated.token.username` instead of the hardcoded `'driver_001'` when dispatching `StartRoute`.

#### Scenario: StartRoute with authenticated username

- GIVEN the user is authenticated via Keycloak
- WHEN the "Iniciar Nueva Ruta" button is pressed
- THEN `StartRoute` is dispatched with `authState.token.username`

#### Scenario: Edge — username is null

- GIVEN `TokenResponse.username` is null
- WHEN `StartRoute` is dispatched
- THEN the driverId defaults to `'unknown'`

### R7: WebSocketService SHALL accept numberPlate as constructor parameter

`WebSocketService` MUST receive `numberPlate` via constructor, replacing the hardcoded `'ABC-123'`. The field is used in STOMP message envelope.

#### Scenario: numberPlate set at construction

- GIVEN a `WebSocketService` is created with `numberPlate: 'ABC-123'`
- WHEN `sendLocation(point)` sends a STOMP message
- THEN the message body contains `numberPlate: 'ABC-123'`

#### Scenario: numberPlate empty string

- GIVEN a `WebSocketService` is created with `numberPlate: ''`
- WHEN `sendLocation(point)` sends a STOMP message
- THEN the message body contains `numberPlate: ''`
- AND the STOMP server handles the empty value

### R8: AuthService MUST read clientSecret from EnvConfig

Both `login()` and `refreshToken()` MUST obtain `client_secret` from `EnvConfig.authClientSecret` instead of `AppConstants.authClientSecret`.

#### Scenario: Login uses env clientSecret

- GIVEN `.env` contains `AUTH_CLIENT_SECRET=xyz`
- WHEN `AuthService.login()` is called
- THEN the HTTP POST body contains `client_secret: 'xyz'`

#### Scenario: RefreshToken uses env clientSecret

- GIVEN `.env` contains `AUTH_CLIENT_SECRET=xyz`
- WHEN `AuthService.refreshToken()` is called
- THEN the HTTP POST body contains `client_secret: 'xyz'`

### R9: BackgroundTrackingHandler SHALL receive numberPlate before onStart

The main isolate MUST send `numberPlate` to the foreground task via `FlutterForegroundTask.sendDataToTask()` after `startService()`. The handler stores it and passes it to `WebSocketService` constructor.

#### Scenario: numberPlate sent to background on route start

- GIVEN the BLoC starts the foreground task
- WHEN `FlutterForegroundTask.startService()` completes
- THEN `sendDataToTask({'type': 'config', 'numberPlate': 'ABC-123'})` is called
- AND `BackgroundTrackingHandler.onReceiveData` stores the value

#### Scenario: Handler constructs WebSocketService with numberPlate

- GIVEN the handler received `numberPlate` via `onReceiveData`
- WHEN `onStart()` creates `WebSocketService`
- THEN the service is constructed with the received numberPlate

## Constraints

- `SharedPreferences.getInstance()` is async — `EnvConfig.numberPlate` MAY cache the value after first read
- New env keys MUST be documented in `.env.example`
- `flutter_dotenv` MUST be added to `pubspec.yaml` under `dependencies`
- `.env` MUST be listed in `assets:` in `pubspec.yaml`
- `.env` is in `.gitignore`; `.env.example` is tracked
