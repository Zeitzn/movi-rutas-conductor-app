# Delta for config-extraction — EnvConfig Integration

## ADDED Requirements

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

## REMOVED Requirements

### `AppConstants.authClientSecret`

(Reason: Moved to `.env` via `flutter_dotenv`. The hardcoded secret in source posed a credential leak risk.)
(Migration: `EnvConfig.authClientSecret` replaces direct access. The constant is retained in `AppConstants` as a fallback comment for one cycle, then removed.)

## Constraints

- `AppConstants.authClientSecret` MUST be deleted from source (no fallback — env is mandatory)
- `numberPlate` default `''` is handled — STOMP may reject empty plates; that is a server-side concern out of scope
- PKCE is NOT implemented in this change — documented as future work in `EnvConfig`
