# AGENTS.md — Movi Rutas Conductor

Flutter 3.38.4 app for drivers: GPS route tracking with WebSocket STOMP publishing, background location, and Keycloak OAuth2 auth.

## Commands

- All Flutter commands use **`fvm flutter ...`** (FVM manages the pinned SDK version)
- `fvm flutter analyze` — static analysis (flutter_lints recommended set, no custom rules)
- `fvm flutter test` — run tests (currently just a placeholder, no real tests exist)
- `fvm flutter run -d linux` — desktop dev (fastest iteration)
- `fvm flutter build apk --debug` — APK build
- NDK corruption fix: `rm -rf $ANDROID_HOME/ndk/27.0.12077973 && fvm flutter clean && fvm flutter pub get`
- No CI, no pre-commit hooks, no Makefile

## Architecture

Feature-based under `lib/features/{route_tracking,auth}/`, each with:
`bloc/ models/ pages/ repositories/ services/`

Shared under `lib/core/`: `constants/ errors/ services/`

- **BLoC** with `flutter_bloc` + `equatable` (canonical usage)
- **Repository pattern**: abstract interface + concrete impl (`RouteRepository`, `IAuthRepository`)
- **Services**: concrete classes, no abstractions (except `AuthService`)
- **Error hierarchy**: `PermissionFailure`, `LocationFailure`, `DatabaseFailure`, etc. in `core/errors/failures.dart`

## Key quirks (will surprise you)

- **Dual location sources**: BLoC listens to BOTH `BackgroundCommunicationService.locationStream` (from background isolate) AND `LocationService.getLocationStream()` (main isolate), deduplicating by timestamp < 500ms
- **`BackgroundCommunicationService`** is a static singleton (not injectable) — pragmatic because Flutter foreground task callbacks can't receive DI. Untestable by design.
- **`WebSocketService`** hardcodes `numberPlate: 'ABC-123'` with a TODO
- **`InMemoryRouteRepository`** is a placeholder — no real persistence. Auth persistence IS real (`SharedPrefsAuthRepository` with in-memory cache).
- **Auth**: `password.toUpperCase()` transformation required by legacy Keycloak backend. Token auto-refresh scheduled at 80% of token lifetime.
- **Background isolate**: `BackgroundTrackingHandler` runs in a SEPARATE isolate. Communicates via `FlutterForegroundTask.sendDataToMain()`. Cannot access BLoC or `BackgroundCommunicationService` directly.
- STOMP WebSocket URL and credentials are hardcoded in `lib/core/constants/app_constants.dart` (not env vars).

## Style conventions (from docs/estandares/estilo.md)

- Identifiers/code in **English**, UI strings in **Spanish**
- `const` everywhere possible, `super.key` on all widgets
- `final` over `var`, no `dynamic` in models
- No `setState` for shared state (use BLoC)
- No `utils/ helpers/ common/` — use `core/` with semantic names
- Imports: dart: → package: → project (blank line separators)

## Testing

- Only `test/widget_test.dart` exists — a TODO placeholder
- No unit, widget, or integration tests written yet
- Stack: `flutter_test` only. Files: `_test.dart` suffix, per feature

## WebSocket / STOMP

- `stomp_dart_client` for STOMP protocol
- Queue-based: messages buffered when disconnected, flushed on reconnect
- Heartbeat every 10s, reconnect delay 5s
- Background isolate opens its OWN independent WebSocket connection (separate from main isolate's)

## Environment

- Android API 29+, NDK 27.0.12077973, JDK 17+
- No `.env` files tracked. `.env.local` for local overrides (in `.gitignore`)
- All config lives in `AppConstants` (hardcoded)
- AI agent prompts in `ai/` dir: publisher and subscriber templates
- Architecture standards in `docs/estandares/` (10 files: bloc, testing, estilo, etc.)
