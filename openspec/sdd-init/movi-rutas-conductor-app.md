## sdd-init: movi-rutas-conductor-app

### Summary
- Project: movi-rutas-conductor-app (Flutter)
- Detected stack and patterns: Flutter/Dart, Bloc (flutter_bloc), feature-based structure under lib/features/{auth,route_tracking}, background task using flutter_foreground_task + workmanager, WebSocket/STOMP via stomp_dart_client, EnvConfig via flutter_dotenv + assets/.env, in-memory route repository placeholder, and SharedPreferences for auth state. Tests use flutter_test with unit/widget layers largely placeholder.

### Architecture patterns observed
- State management: flutter_bloc + equatable
- Repository pattern: InMemoryRouteRepository for routes; SharedPrefsAuthRepository for auth
- Background location: foreground task isolates + Workmanager integration; background data bridge via BackgroundCommunicationService
- WebSocket/STOMP: stomp_dart_client with hardcoded AYAC/001 topic and /AYAC/001 channel path in AppConstants
- Environment/config: EnvConfig reading from assets/.env and SharedPreferences (Env secret and numberPlate)

### Testing capabilities
- Flutter testing via flutter_test; unit tests exist under test/features/route_tracking/models, widget_test.dart is a placeholder and marked TODO. Strict TDD is currently disabled in openspec config.

### Environment & secrets
- Secrets: AUTH_CLIENT_SECRET loaded from assets/.env; PROFILES_API_BASE_URL configured in assets/.env
- Public environment keys read via EnvConfig (PROFILES_API_BASE_URL, AUTH_CLIENT_SECRET)

### Skill registry / Compact Rules
- A Skill Registry is present in the project scope. See .atl/skill-registry.md for a compact rules summary (auto-generated).

### Recommendations / Next steps
- Consider enabling strict TDD by adding real tests and updating openspec/config.yaml accordingly.
- Extract the hardcoded WebSocket topic and destination into a config that can be overridden per environment.
- If not yet, move hardcoded environment constants into the EnvConfig-based configuration layer.

### Artifacts
- Reference Engram ID: obs-f4ad02bc4857ba76
