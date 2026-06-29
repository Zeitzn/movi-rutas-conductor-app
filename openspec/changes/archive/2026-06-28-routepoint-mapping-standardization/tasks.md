# Tasks: Estandarización del mapeo de RoutePoint

## Review Workload Forecast

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

| Field | Value |
|-------|-------|
| Estimated changed lines | ~130-150 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Core impl (R1-R3 + caller) | PR 1 | main |
| 2 | Tests + verify (R4 + analyze) | Mismo PR | Mismo commit |

## Phase 1: Core Implementation

- [x] 1.1 BTH — reemplazar Map manual por `RoutePoint(position).toJson()` + `'type': 'location'` [`lib/features/route_tracking/services/background_tracking_handler.dart`, líneas 50-58]
- [x] 1.2 RTB — usar `RoutePoint.fromJson(data)` en stream background (data es `Map<String,dynamic>`) [`lib/features/route_tracking/bloc/route_tracking_bloc.dart`, líneas 97-106]
- [x] 1.3 RTB — extraer Map desde `Position` y usar `RoutePoint.fromJson()` en stream main [`lib/features/route_tracking/bloc/route_tracking_bloc.dart`, líneas 116-123]
- [x] 1.4 WSS.sendLocation — cambiar firma a `sendLocation(RoutePoint point)` y reusar `point.toJson()` como base para STOMP [`lib/features/route_tracking/services/websocket_service.dart`, líneas 85-120]
- [x] 1.5 BTH._handleLocationUpdate — actualizar caller de `sendLocation` para pasar un `RoutePoint` en vez de 5 parámetros [`lib/features/route_tracking/services/background_tracking_handler.dart`, líneas 69-75]

## Phase 2: Testing

- [x] 2.1 Crear test roundtrip `toJson/fromJson` con todos los campos poblados [`test/features/route_tracking/models/route_point_test.dart`]
- [x] 2.2 Crear test roundtrip con opcionales nulos (speed=null, accuracy=null, altitude=null) [mismo archivo]

## Phase 3: Verification

- [x] 3.1 Ejecutar `flutter analyze` — 0 errores, 0 warnings
- [ ] 3.2 Verificar que el backend STOMP tolera `altitude: null` en el mensaje ⚠️ requiere entorno real
- [x] 3.3 Ejecutar `flutter test` — nuevos tests pasan (2/2)
