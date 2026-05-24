# Servicios

## Principios

- Una clase por responsabilidad (ubicación, websocket, notificaciones, etc.).
- Servicios con estado (conexiones, streams) se usan como instancia.
- Métodos estáticos solo para utilidades sin estado (notificaciones foreground).
- No acoplar servicios entre sí. Si necesitan comunicación, que el BLoC orqueste.
- Ubicación: `features/<feature>/services/`.

## LocationService

```dart
class LocationService {
  Future<bool> hasLocationPermission() async { ... }
  Stream<Position> getLocationStream() { ... }
  Future<void> openLocationSettings() async { ... }
}
```

### Responsabilidades
- Verificar y solicitar permisos de ubicación.
- Proveer stream de posición GPS con configuración de alta precisión.
- Abrir configuración del dispositivo para activar GPS.

### Lo que NO hace
- No guarda puntos de ruta (lo hace el BLoC con el repositorio).
- No maneja la lógica de negocio de rutas.
- No se suscribe a nada por sí mismo (devuelve un Stream para que el BLoC lo escuche).

## BackgroundLocationService

```dart
class BackgroundLocationService {
  // Métodos de instancia (usados desde callbackDispatcher en main.dart)
  Future<void> initializeBackgroundTask() async { ... }
  Future<Position?> getCurrentLocationForBackground() async { ... }
  Future<void> saveLocationPoint(Position position) async { ... }
  Future<void> sendLocationToWebSocket(Position position) async { ... }

  // Métodos estáticos (usados desde el BLoC para notificaciones foreground)
  static Future<void> startForegroundNotification() async { ... }
  static Future<void> updateNotificationStatus(RouteStatus status, int points) async { ... }
  static Future<void> stopForegroundNotification() async { ... }
}
```

### Reglas
- El `callbackDispatcher` se declara **ÚNICAMENTE** en `main.dart` con `@pragma('vm:entry-point')`.
- Las notificaciones foreground se manejan via `MethodChannel`.
- Los métodos que reciben `Position` se usan desde el callback del WorkManager.

## Inyección

```dart
// main.dart
RepositoryProvider<LocationService>(
  create: (context) => LocationService(),
),
```

Los servicios se inyectan via `RepositoryProvider` y se consumen en el BLoC por constructor.
