# Manejo de errores

## Jerarquía de Failure

Jerarquía plana, sin anidamiento. Todos extienden `Failure`.

```dart
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'Failure(message: $message)';
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
```

## Cuándo usar cada uno

| Failure | Uso |
|---|---|
| `LocationFailure` | GPS desactivado, error al obtener ubicación |
| `PermissionFailure` | Permisos denegados, denegados permanentemente |
| `NetworkFailure` | Errores de conexión de red |
| `DatabaseFailure` | Errores de almacenamiento local (Hive, SQLite, memoria) |
| `ServerFailure` | Errores de API o WebSocket |
| `UnknownFailure` | Fallback genérico |

## Patrón de uso

### Envolver excepciones externas

```dart
try {
  return await Geolocator.getCurrentPosition(...);
} catch (e) {
  if (e is Failure) rethrow;
  throw LocationFailure('Failed to get current location: $e');
}
```

### En repositorios

```dart
@override
Future<Route> createRoute(Route route) async {
  try {
    _routes[route.id] = route;
    return route;
  } catch (e) {
    throw DatabaseFailure('Failed to create route: $e');
  }
}
```

### En BLoCs

Los BLoCs capturan `Failure` y lo convierten en estado de error:

```dart
try {
  // ... lógica ...
  emit(RouteTrackingInProgress(_currentRoute!));
} catch (e) {
  emit(RouteTrackingError('Failed to start route: $e'));
}
```

## Reglas

- **Jerarquía plana.** No anidar subtipos de Failure.
- **`rethrow`** cuando ya es un `Failure` para no duplicar wrappers.
- **`UnknownFailure`** solo como último recurso. Preferir el tipo específico.
- Los `Failure` son inmutables (campos `final`).
- Ubicación: `lib/core/errors/failures.dart`.
