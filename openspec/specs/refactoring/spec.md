# Refactoring Specification — Quick Wins

## Overview

Four independent refactoring items. Zero behavioral change to tracking, auth, or WebSocket.

| # | Change | Files | Lines | Risk |
|---|--------|-------|-------|------|
| 1 | Notification sound: remove from GPS sends | `websocket_service.dart` | −2 | Low |
| 2 | `print()` → `debugPrint()` | 3 files (19 calls) | Bulk replace | Low |
| 3 | Dead code: delete orphaned artifacts | 5 files | Delete unreachable code | Low |
| 4 | Timestamp skew — EXCLUDED | — | Verify on device first | — |

## Requirements

### R1: Notification Sound — GPS sends MUST NOT trigger `playNotification()`

The `playNotification()` call in `sendLocation()` (line 110) and `_flushMessageQueue()` (line 132) MUST be removed. The `_ringtonePlayer` field MUST be preserved for future connect/disconnect use.

#### Scenario: No audio on location send

- GIVEN the STOMP client is connected
- WHEN `sendLocation()` publishes coordinates
- THEN location is sent via STOMP
- AND `playNotification()` is NOT invoked

#### Scenario: No audio on queue flush

- GIVEN queued messages exist after reconnection
- WHEN `_flushMessageQueue()` delivers each message
- THEN all messages are sent successfully
- AND `playNotification()` is NOT invoked

#### Scenario: Audio preserved on lifecycle events

- GIVEN a connection, disconnection, or protocol error occurs
- WHEN `onConnect`, `onDisconnect`, `onWebSocketError`, or `onStompError` fires
- THEN existing notification sound behavior is UNCHANGED

### R2: print() → debugPrint() — All logs MUST use `debugPrint()`

All 19 `print(` calls in the three target files MUST be replaced with `debugPrint(`. Each file MUST add `import 'package:flutter/foundation.dart'` — `debugPrint` is defined there, not auto-exported in non-Material files.

| File | Calls Replaced |
|------|---------------|
| `websocket_service.dart` | 16 |
| `background_communication_service.dart` | 2 |
| `background_location_service.dart` | 1 |

#### Scenario: Websocket service uses debugPrint

- GIVEN `websocket_service.dart`
- WHEN any of the 16 log lines executes (connect, disconnect, send, flush, subscribe, errors)
- THEN `debugPrint(...)` is used instead of `print(...)`

#### Scenario: Background communication uses debugPrint

- GIVEN `background_communication_service.dart`
- WHEN `onTaskData` logs unexpected data types or catch errors
- THEN `debugPrint(...)` is used instead of `print(...)`

#### Scenario: Background location uses debugPrint

- GIVEN `background_location_service.dart`
- WHEN `saveLocationPoint` logs a route point
- THEN `debugPrint(...)` is used instead of `print(...)`

### R3: Dead Code — Orphaned artifacts MUST be deleted

(Previously: Dead code existed but was never dispatched or reached at runtime.)

| Artifact | File | Action |
|----------|------|--------|
| `LoadRoute` event class | `route_tracking_event.dart` | Delete class |
| `RouteTrackingLoaded` state class | `route_tracking_state.dart` | Delete class |
| `on<LoadRoute>` registration | `route_tracking_bloc.dart` | Delete line 36 |
| `_onLoadRoute` handler | `route_tracking_bloc.dart` | Delete method (lines 277–294) |
| `RouteTrackingLoaded` branch | `route_tracking_page.dart` | Delete branch (lines 52–53) |
| `_buildLoadedState` method | `route_tracking_page.dart` | Delete (lines 276–278) |
| `_buildRouteDetails` method | `route_tracking_page.dart` | Delete (lines 369–386) |
| `_buildRecentLocationsCard` method | `route_tracking_page.dart` | Delete (lines 415–457) |
| `_formatDateTime` private helper | `route_tracking_page.dart` | Delete (only caller was `_buildRecentLocationsCard`) |
| `RouteStatus.cancelled` value | `route_status.dart` | Delete enum value + switch arm |

#### Scenario: Clean compilation after deletion

- GIVEN the 5 affected files
- WHEN `fvm flutter analyze` is executed
- THEN zero errors or warnings related to the deleted artifacts

#### Scenario: _buildStatusCard preserved

- GIVEN `route_tracking_page.dart`
- WHEN dead code is removed
- THEN `_buildStatusCard` (lines 388–413) is preserved and used by `_buildPausedState`

#### Scenario: Route flow unaffected

- GIVEN a device running the app
- WHEN the user starts → pauses → resumes → ends a route
- THEN each transition works correctly without crashes

### R4: Timestamp Skew — EXCLUDED

The `DateTime.now()` → `position.timestamp` fix in `background_tracking_handler.dart` MUST NOT be applied in this change. Device verification is required before implementation.

#### Scenario: No timestamp changes applied

- GIVEN `background_tracking_handler.dart` line 47
- WHEN this refactoring is applied
- THEN `DateTime.now()` is NOT modified
- AND `position.timestamp` is NOT substituted

## Constraints

- `_ringtonePlayer` field in `WebSocketService` — KEPT (used by lifecycle event paths)
- `_buildStatusCard` widget — KEPT (shared with `RouteTrackingPaused` state)
- `debugPrint` requires `import 'package:flutter/foundation.dart'` in non-Material files
- All four items independently revertible via git

## Non-Changes (Explicitly Out of Scope)

These MUST remain untouched:
- WebSocket connectivity, reconnection delay, heartbeat interval
- Route tracking lifecycle (start → pause → resume → end)
- Dual-source location deduplication (500ms guard)
- Route point serialization / isolate bridge mapping
- Hardcoded config (`numberPlate`, `driver_001`, `authClientSecret`)
