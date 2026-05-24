# Repositorios (patrón)

## Definición

Cada feature define una interfaz abstracta y al menos una implementación concreta.

```dart
abstract class RouteRepository {
  Future<Route> createRoute(Route route);
  Future<Route> updateRoute(Route route);
  Future<Route?> getRouteById(String routeId);
  Future<List<Route>> getRoutesByDriverId(String driverId);
  Future<List<Route>> getAllRoutes();
  Future<void> deleteRoute(String routeId);
  Future<void> clearAllRoutes();
}
```

## Implementación

```dart
class InMemoryRouteRepository implements RouteRepository {
  final Map<String, Route> _routes = {};
  final Map<String, List<String>> _driverRoutes = {};

  @override
  Future<Route> createRoute(Route route) async {
    try {
      _routes[route.id] = route;

      if (!_driverRoutes.containsKey(route.driverId)) {
        _driverRoutes[route.driverId] = [];
      }
      _driverRoutes[route.driverId]!.add(route.id);

      return route;
    } catch (e) {
      throw DatabaseFailure('Failed to create route: $e');
    }
  }

  @override
  Future<Route> updateRoute(Route route) async {
    try {
      if (!_routes.containsKey(route.id)) {
        throw const DatabaseFailure('Route not found');
      }
      _routes[route.id] = route;
      return route;
    } catch (e) {
      if (e is DatabaseFailure) rethrow;
      throw DatabaseFailure('Failed to update route: $e');
    }
  }

  @override
  Future<Route?> getRouteById(String routeId) async {
    try {
      return _routes[routeId];
    } catch (e) {
      throw DatabaseFailure('Failed to get route: $e');
    }
  }

  @override
  Future<List<Route>> getRoutesByDriverId(String driverId) async {
    try {
      final routeIds = _driverRoutes[driverId] ?? [];
      return routeIds.map((id) => _routes[id]!).toList();
    } catch (e) {
      throw DatabaseFailure('Failed to get routes for driver: $e');
    }
  }

  @override
  Future<List<Route>> getAllRoutes() async {
    try {
      return _routes.values.toList();
    } catch (e) {
      throw DatabaseFailure('Failed to get all routes: $e');
    }
  }

  @override
  Future<void> deleteRoute(String routeId) async {
    try {
      final route = _routes[routeId];
      if (route == null) throw const DatabaseFailure('Route not found');

      _routes.remove(routeId);
      _driverRoutes[route.driverId]?.remove(routeId);

      if (_driverRoutes[route.driverId]?.isEmpty == true) {
        _driverRoutes.remove(route.driverId);
      }
    } catch (e) {
      if (e is DatabaseFailure) rethrow;
      throw DatabaseFailure('Failed to delete route: $e');
    }
  }

  @override
  Future<void> clearAllRoutes() async {
    try {
      _routes.clear();
      _driverRoutes.clear();
    } catch (e) {
      throw DatabaseFailure('Failed to clear all routes: $e');
    }
  }
}
```

## Reglas

- **Interfaz abstracta primero**, implementación concreta después.
- **Métodos async siempre** (incluso si la implementación actual es sincrónica en memoria).
- **Lanzar `Failure`** en lugar de excepciones genéricas.
- Capturar excepciones externas y envolverlas en `DatabaseFailure`.
- Usar `rethrow` si ya es un `Failure`.
- Nombrar con sufijo `Repository`.
- Ubicación: `features/<feature>/repositories/`.

## Registro

```dart
RepositoryProvider<RouteRepository>(
  create: (context) => InMemoryRouteRepository(),
),
```

El `RepositoryProvider` se registra en el árbol de widgets (en `main.dart`) para que BLoCs y pages lo consuman via `context.read<RouteRepository>()`.
