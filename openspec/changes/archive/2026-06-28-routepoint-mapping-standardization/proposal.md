# Propuesta: Estandarización del mapeo de RoutePoint

## Intención

Eliminar la triple duplicación del mapeo de `RoutePoint` en background isolate, BLoC y WebSocket. Hoy `RoutePoint.toJson()` y `fromJson()` existen pero no se usan en ninguno de los 3 sitios de serialización. Cualquier campo nuevo requiere tocar 3+ sitios manualmente, con riesgo de error.

## Alcance

### In Scope
- BackgroundTrackingHandler: reemplazar el `Map` manual con `RoutePoint.toJson()` + campo `type`
- RouteTrackingBloc: reemplazar el constructor manual con `RoutePoint.fromJson()`
- WebSocketService.sendLocation: refactorizar para recibir `RoutePoint` y usar `toJson()` como base, mergeando campos STOMP
- Tests unitarios para `RoutePoint.toJson()` / `fromJson()` roundtrip

### Out of Scope
- Cambiar el protocolo STOMP (formato del mensaje enviado)
- Resolver el hardcode de `numberPlate: 'ABC-123'`
- Refactorizar `Route` — ya usa `RoutePoint.toJson()` correctamente

## Capacidades

### Nuevas Capacidades
Ninguna — cambio puramente de refactorización interna.

### Capacidades Modificadas
Ninguna — no cambia comportamiento observable ni requisitos de especificación.

## Enfoque

1. **BackgroundTrackingHandler**: construir `RoutePoint(position)` → `toJson()` → agregar `'type': 'location'` → `jsonEncode`. El handler importa el modelo (mismo package, isolate compatible).
2. **RouteTrackingBloc**: cambiar `RoutePoint(lat: data['latitude']...)` por `RoutePoint.fromJson(data)`. El BLoC ya importa `route_point.dart`.
3. **WebSocketService.sendLocation**: cambiar firma a `sendLocation(RoutePoint point)`. Usar `point.toJson()` como base, mergear `sender`, `numberPlate`, `content` con `{...point.toJson()}`.
4. **Prueba**: test unitario que construye `RoutePoint`, llama `toJson()`, después `fromJson()`, verifica igualdad.

## Archivos Afectados

| Archivo | Impacto | Descripción |
|---------|---------|-------------|
| `services/background_tracking_handler.dart` | Modificado | Serialización Position→Map usando toJson() |
| `bloc/route_tracking_bloc.dart` | Modificado | Deserialización Map→RoutePoint usando fromJson() |
| `services/websocket_service.dart` | Modificado | sendLocation recibe RoutePoint, reusa toJson() |
| `models/route_point.dart` | Sin cambios | Ya tiene toJson/fromJson funcionales |

## Riesgos

| Riesgo | Probabilidad | Mitigación |
|--------|-------------|------------|
| Background isolate preservado tras hot restart con formato viejo | Media | Documentar en el PR. Forzar stop/start del foreground task después del cambio |
| WebSocket envía campos extra (altitude como null) que el backend rechaza | Baja | Verificar que el backend tolera campos desconocidos. El formato STOMP actual NO envía `altitude` |
| Isolate bridge: sendDataToMain usa String JSON — compatible | Baja | fromJson parsea el mismo Map que antes, solo cambia el origen de los valores |

## Plan de Rollback

Revetir los 3 archivos con `git revert`. El comportamiento es idéntico — no hay migración de datos ni cambios de esquema.

## Dependencias

Ninguna.

## Criterios de Éxito

- [ ] `RoutePoint.toJson()` → `jsonEncode` → `jsonDecode` → `RoutePoint.fromJson()` produce el mismo objeto
- [ ] La UI recibe ubicaciones del background después del cambio
- [ ] El WebSocket envía mensajes STOMP con el mismo formato (sender, numberPlate, content preservados)
- [ ] `flutter analyze` sin errores ni warnings
- [ ] Prueba en dispositivo real: ruta completa (inicio, pausa, reanudación, fin) sin pérdida de puntos
