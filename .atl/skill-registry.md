## Skill Registry (Compact Rules) for movi-rutas-conductor-app

- sdd-init/movi-rutas-conductor-app: Initialize SDD context for the project. Triggers: /sdd-init command; artifacts: Engram + OpenSpec outputs; registry: maintained for upserts.
- openspec/config.yaml: Project config and mode (hybrid) to persist Engram + OpenSpec artifacts.
- env-config: Env-based config for secrets and endpoints; numberPlate persisted in SharedPreferences.
- websocket-service: STOMP over WebSocket with AYAC/001 path hardcoded in AppConstants; consider externalizing.
- testing: flutter_test runner; unit tests under test/features/route_tracking/models/; widget tests placeholder.

Note: This registry is a lightweight, auto-generated map of available skills/triggers for this repository. It is intended to assist subsequent sdd-explore/sdd-propose steps.
