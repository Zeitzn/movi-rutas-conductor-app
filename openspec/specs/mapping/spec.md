# RoutePoint Mapping Specification

## Purpose

Estandarizar la serialización/deserialización de `RoutePoint` en los 3 puntos de mapeo (background isolate, BLoC, WebSocket) para que todos usen `RoutePoint.toJson()` y `RoutePoint.fromJson()` en lugar de constructores manuales de `Map<String, dynamic>`.

## Requirements

### R1: BackgroundTrackingHandler — Serialización MUST usar RoutePoint.toJson()

El handler MUST construir `RoutePoint` desde `Position`, llamar `toJson()`, mergear `'type': 'location'`, y codificar con `jsonEncode`. El `Map` manual en líneas 50–58 MUST ser reemplazado.

#### Scenario: Position serializada via RoutePoint.toJson()

- GIVEN un `Position` válido con latitud, longitud, speed, accuracy, altitude, timestamp
- WHEN `_handleLocationUpdate` construye el mensaje para el main isolate
- THEN el mensaje se construye via `RoutePoint(position).toJson()` más `'type': 'location'`
- AND todos los campos (latitude, longitude, speed, accuracy, altitude) están presentes en el JSON

#### Scenario: Edge — campos opcionales nulos

- GIVEN un `Position` donde speed, accuracy, o altitude son null
- WHEN se llama `RoutePoint(position).toJson()`
- THEN el Map JSON contiene esas keys con valor null (matching current behavior)

### R2: RouteTrackingBloc — Deserialización MUST usar RoutePoint.fromJson()

Los dos constructores manuales `RoutePoint(lat: ..., long: ...)` en líneas 97–106 y 116–123 MUST ser reemplazados por `RoutePoint.fromJson(data)`. El Map de entrada no cambia — solo la ruta de construcción.

#### Scenario: Stream principal deserializado via fromJson

- GIVEN un `Position` de `LocationService.getLocationStream()`
- WHEN el BLoC lo convierte a `RoutePoint`
- THEN se usa `RoutePoint.fromJson(mapWithFields)` extrayendo lat/long/timestamp/speed/accuracy/altitude del Position

#### Scenario: Bridge del background isolate deserializado via fromJson

- GIVEN un `Map<String, dynamic>` de `BackgroundCommunicationService.locationStream`
- WHEN el BLoC lo convierte a `RoutePoint`
- THEN se usa `RoutePoint.fromJson(data)` en lugar de extracción manual de campos

#### Scenario: Edge — campos nulos en fromJson

- GIVEN un Map donde speed, accuracy, o altitude están ausentes o son null
- WHEN se llama `RoutePoint.fromJson(data)`
- THEN esos campos son null en el `RoutePoint` resultante

### R3: WebSocketService.sendLocation — Firma MUST recibir RoutePoint

El método `sendLocation` MUST aceptar un `RoutePoint` y reemplazar los 5 parámetros posicionales. El mensaje STOMP MUST construirse esparciendo `point.toJson()` y agregando campos STOMP (`sender`, `numberPlate`, `content`).

#### Scenario: Mensaje STOMP construido desde RoutePoint.toJson()

- GIVEN un `RoutePoint` con latitud, longitud, speed, accuracy, altitude, timestamp
- WHEN se llama `sendLocation(point)`
- THEN el body del mensaje STOMP contiene todos los campos de `RoutePoint` más `sender`, `numberPlate`, y `content`

#### Scenario: Campos del envelope STOMP preservados

- GIVEN un STOMP client conectado
- WHEN se llama `sendLocation(point)`
- THEN el mensaje contiene `sender: AppConstants.websocketRemitente`
- AND `numberPlate: 'ABC-123'`
- AND `content: 'Coordenadas GPS: {lat}, {lng}'`

#### Scenario: Edge — campos nulos en mensaje STOMP

- GIVEN un `RoutePoint` donde altitude es null
- WHEN `sendLocation(point)` construye el mensaje
- THEN el JSON STOMP incluye `"altitude": null` (comportamiento previo no enviaba altitude)

### R4: Roundtrip test — RoutePoint.toJson/fromJson MUST verificarse

Un test unitario MUST existir que construye un `RoutePoint`, llama `toJson()`, pasa el resultado a `RoutePoint.fromJson()`, y verifica igualdad via `==` (Equatable).

#### Scenario: Roundtrip completo con todos los campos

- GIVEN un `RoutePoint` con todos los campos poblados
- WHEN se llama `toJson()`, luego el resultado se pasa a `RoutePoint.fromJson()`
- THEN el `RoutePoint` resultante es igual al original via `==`

#### Scenario: Roundtrip con opcionales nulos

- GIVEN un `RoutePoint` con speed=null, accuracy=null, altitude=null
- WHEN se hace roundtrip via toJson/fromJson
- THEN el `RoutePoint` resultante es igual al original via `==`

## Constraints

- `BackgroundTrackingHandler` importa `route_point.dart` — mismo package, sin restricción de isolate
- `WebSocketService.sendLocation` cambia firma → todos los callers actualizados en el mismo cambio
- El test no requiere mocks — `RoutePoint` es puro modelo de datos sin dependencias externas
- El formato del mensaje STOMP enviado NO cambia (out of scope)
- `Route.toJson()` ya usa `RoutePoint.toJson()` correctamente — no se modifica
