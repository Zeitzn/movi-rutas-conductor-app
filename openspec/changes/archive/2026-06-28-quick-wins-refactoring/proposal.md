# Proposal: Quick Wins Refactoring

## Intent

Low-risk cleanup: remove notification spam on every GPS send, replace
`print()` with `debugPrint()`, and delete orphaned code (`LoadRoute`,
`RouteTrackingLoaded`, `RouteStatus.cancelled`). Zero behavioral change
to tracking, auth, or WebSocket.

## Scope

### In Scope
- **Notification sound**: Remove `playNotification()` from `sendLocation()`
  and `_flushMessageQueue()` in `WebSocketService`. Keep on connect/disconnect.
- **print() → debugPrint()**: Replace 19 calls — `websocket_service.dart`
  (16), `background_communication_service.dart` (2),
  `background_location_service.dart` (1).
- **Dead code**: Delete `LoadRoute` event, `RouteTrackingLoaded` state,
  `_onLoadRoute` handler+registration, `RouteTrackingLoaded` branch +
  orphaned widgets (`_buildLoadedState`, `_buildRouteDetails`,
  `_buildRecentLocationsCard`), and `RouteStatus.cancelled` enum value.

### Out of Scope
- Timestamp skew, `BackgroundLocationService` refactor (keep print→debugPrint
  only), config extraction, RoutePoint mapping, defensive try-catch cleanup.

## Capabilities

### New Capabilities
None — pure refactor, no new spec-level capabilities.

### Modified Capabilities
None — zero spec-level behavioral changes.

## Approach

Four independent changes, mergeable in any order:
1. **Notification sound**: Delete 2 `playNotification()` calls in
   `websocket_service.dart` (lines 110, 132). Keep the `_ringtonePlayer`
   field for future connect/disconnect sounds.
2. **print() → debugPrint()**: Bulk replace `print(` → `debugPrint(` in
   the 3 target files. `debugPrint` is re-exported by Flutter from
   `dart:developer` — no import changes needed.
3. **Dead code (LoadRoute chain)**: Delete class, handler, event
   registration, state class, and page branch. Keep `_buildStatusCard`
   (shared with paused state).
4. **Dead code (RouteStatus.cancelled)**: Delete enum value +
   `displayName` switch case.

## Affected Areas

| File | Change |
|------|--------|
| `websocket_service.dart` | −2 `playNotification()`, 16 `print→debugPrint` |
| `background_communication_service.dart` | 2 `print→debugPrint` |
| `background_location_service.dart` | 1 `print→debugPrint` |
| `route_tracking_event.dart` | −`LoadRoute` class |
| `route_tracking_state.dart` | −`RouteTrackingLoaded` class |
| `route_tracking_bloc.dart` | −`_onLoadRoute` + `on<LoadRoute>` |
| `route_tracking_page.dart` | −`RouteTrackingLoaded` branch + 3 orphaned methods |
| `route_status.dart` | −`cancelled` + switch case |

## Risks

| Risk | Mitigation |
|------|------------|
| `cancelled` needed by future backend serialization | Never serialized today; re-add if needed |
| `_buildStatusCard` still used by paused state | Verified — kept, not removed |
| `debugPrint` truncates on some platforms | Same behavior as `print` with throttling; no regression |

## Rollback Plan

Each change independently revertible: 2-line restore for sound, bulk
`sed` reverse for debugPrint, git restore for dead-code deletions.

## Dependencies

None (Flutter SDK only).

## Success Criteria

- [ ] `playNotification()` calls remain only in connect/disconnect paths
- [ ] Zero `print(` calls in the 3 target files
- [ ] `LoadRoute` / `RouteTrackingLoaded` / `RouteStatus.cancelled` gone
- [ ] `fvm flutter analyze` — zero errors
- [ ] Route flow (start→pause→resume→end) works correctly
