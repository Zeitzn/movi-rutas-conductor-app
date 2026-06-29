# Archive Report: WebSocket companyUuid dinámico

**Archived**: 2026-06-29
**Previous location**: `openspec/changes/websocket-companyuuid-dinamico/`
**Archive location**: `openspec/changes/archive/2026-06-29-websocket-companyuuid-dinamico/`

## Specs Synced

No filesystem delta specs to merge (all artifacts lived in Engram).

## Artifacts

| Artifact | Location |
|----------|----------|
| Explore | Engram #169 |
| Proposal | Engram #170 |
| Spec | Engram #171 |
| Design | Engram #172 |
| Tasks | Engram #173 |
| Apply Progress | Engram #174, `apply-progress.md` |
| Archive Report | Engram #177, this file |

## Tasks Summary

- **13/15 tasks completed** (all implementation + most tests)
- **2 blocked** (4.3, 4.4 — require mockito/mocktail, not available)

## Verification

- `fvm flutter analyze`: 0 issues
- `fvm flutter test`: 9/9 pass
- Tested on physical device: ✅ STOMP connects, sends location

## Key Fixes Applied

1. **Race condition**: `BackgroundTrackingHandler.onStart()` runs before config arrives. Fix: defer `WebSocketService` creation to `_handleConfigData()`.
2. **Subscribe guard removed**: Removed `_isConnected` check from `subscribe()` — stomp_dart_client already queues frames internally.
3. **numberPlate now comes from profile username**: `EnvConfig.instance.numberPlate` siempre devolvía `''` porque nunca se escribía en SharedPrefs. Ahora `numberPlate` se lee del `username` del perfil del conductor (`profile?.username`), que es el mismo valor que se muestra en el appbar. Afecta `RouteTrackingBloc` y `callbackDispatcher`.
4. **App es solo emisora**: Eliminado `subscribe()` completamente. La app solo envía ubicación GPS, no recibe datos del WebSocket.
