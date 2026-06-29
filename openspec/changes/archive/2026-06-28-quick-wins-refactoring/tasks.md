# Tasks: Quick Wins Refactoring

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~140 (101 deleted, 19 modified) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | single PR |
| Delivery strategy | auto-chain |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | All refactorings + verify | PR 1 | Single PR, <400 lines, all independent |


## Phase 1: Notification Sound — R1 (websocket_service.dart)

- [x] 1.1 Remove `playNotification()` from `sendLocation()` (line 110)
- [x] 1.2 Remove `playNotification()` from `_flushMessageQueue()` (line 132)
- [x] 1.3 Verify: `playNotification()` only remains in lifecycle callbacks

## Phase 2: Dead Code — R3 (5 files)

- [x] 2.1 Delete `LoadRoute` class from `route_tracking_event.dart` (lines 41-48)
- [x] 2.2 Delete `RouteTrackingLoaded` class from `route_tracking_state.dart` (lines 38-45)
- [x] 2.3 Remove `on<LoadRoute>` + `_onLoadRoute` handler from `route_tracking_bloc.dart` (lines 36, 277-294)
- [x] 2.4 Remove `RouteTrackingLoaded` branch (lines 52-53) + `_buildLoadedState` (276-278) + `_buildRouteDetails` (369-386) + `_buildRecentLocationsCard` (415-457) from `route_tracking_page.dart`
- [x] 2.5 Delete `cancelled` value + switch case from `route_status.dart` (line 6, lines 18-19)
- [x] 2.6 Verify: no references to deleted artifacts remain

## Phase 3: print() → debugPrint() — R2 (3 files)

- [x] 3.1 Replace 16 `print(` → `debugPrint(` in `websocket_service.dart`
- [x] 3.2 Replace 2 `print(` → `debugPrint(` in `background_communication_service.dart`
- [x] 3.3 Replace 1 `print(` → `debugPrint(` in `background_location_service.dart`
- [x] 3.4 Verify: zero `print(` calls remain in target files

## Phase 4: Final Verification

- [x] 4.1 Run `fvm flutter analyze` — zero errors
- [x] 4.2 ~~Smoke test route flow (start → pause → resume → end)~~ — RECONCILED AT ARCHIVE: manual device test pending. verify-report PASSED all 4 specs + compilation. User explicitly authorized archive. sdd-archive exceptional reconciliation.
