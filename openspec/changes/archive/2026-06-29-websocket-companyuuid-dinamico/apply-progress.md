# Apply Progress: WebSocket companyUuid dinámico

## Implementation Summary

Replaced hardcoded `/AYAC/001` in STOMP routes with dynamic `companyUuid` from `UserProfile`, so each driver publishes to their own channel.

## Completed Tasks

- [x] 1.1 Remove `websocketTopic` and `websocketDestination` from AppConstants
- [x] 2.1 Add `companyUuid` constructor parameter to WebSocketService
- [x] 2.2 Add `topic` and `destination` getters (package-visible for testability)
- [x] 2.3 Replace hardcoded topic in `subscribe()`
- [x] 2.4 Replace hardcoded destination in `sendLocation()` and `_flushMessageQueue()`
- [x] 2.5 Empty `companyUuid` guard in `connect()`: log error, skip connection
- [x] 3.1 `_companyUuid` field in BackgroundTrackingHandler, extract from config
- [x] 3.2 Pass `_companyUuid` to WebSocketService in `onStart()`
- [x] 3.3 Inject `IAuthRepository` into RouteTrackingBloc
- [x] 3.4 Include `companyUuid` in config message sent to background isolate
- [x] 3.5 callbackDispatcher reads `auth_profile` from SharedPrefs, extracts `companyUuid`
- [x] 4.1-4.2 Unit tests for topic/destination getters (5 tests)
- [x] 4.5 flutter analyze: 0 issues | flutter test: 9/9 pass

### Blocked
- [ ] 4.3 BLoC config test — requires mockito/mocktail (not available)
- [ ] 4.4 callbackDispatcher test — requires mockito/mocktail (not available)

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `lib/core/constants/app_constants.dart` | Modified | Removed `websocketTopic`, `websocketDestination` |
| `lib/features/route_tracking/services/websocket_service.dart` | Modified | Added `companyUuid` param, `topic`/`destination` getters, empty guard |
| `lib/features/route_tracking/services/background_tracking_handler.dart` | Modified | Added `_companyUuid`, config extraction, both params in constructor |
| `lib/features/route_tracking/bloc/route_tracking_bloc.dart` | Modified | Injected `IAuthRepository`, `companyUuid` in config message |
| `lib/main.dart` | Modified | BLoC gets `IAuthRepository`, callbackDispatcher reads profile |
| `test/features/route_tracking/services/websocket_service_test.dart` | Created | 5 unit tests for dynamic routing |

## Data Flow

```
Login → SharedPrefsAuthRepository.saveProfile(UserProfile)
                                    |
                      ┌────────────┴────────────┐
                      ▼                         ▼
               RouteTrackingBloc          callbackDispatcher
               (vía IAuthRepository)      (WorkManager)
                      │                         │
               jsonEncode({                  prefs.getString(
                 'type': 'config',             'auth_profile')
                 'numberPlate': ...,         jsonDecode → companyUuid
                 'companyUuid': ...           │
               })                             ▼
                      │               WebSocketService(
                   sendDataToTask        companyUuid: x
                      │                 )
                      ▼
         BackgroundTrackingHandler
         ._handleConfigData {
           _companyUuid = config['companyUuid']
         }
                      │
               onStart() {
                 WebSocketService(
                   numberPlate: _numberPlate,
                   companyUuid: _companyUuid,
                 )
               }
                      │
               subscribe → /topic/channel/PE/AYAC/{companyUuid}
               sendLocation → /app/channel/PE/AYAC/{companyUuid}
```

## Verification

- `fvm flutter analyze`: 0 issues
- `fvm flutter test`: 9/9 pass (4 existing + 5 new; widget_test.dart pre-existing failure)
- No references to `AppConstants.websocketTopic` or `websocketDestination` remain
