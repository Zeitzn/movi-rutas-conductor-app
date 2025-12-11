import '../models/route.dart';
import '../../../core/errors/failures.dart';

abstract class RouteRepository {
  Future<Route> createRoute(Route route);
  Future<Route> updateRoute(Route route);
  Future<Route?> getRouteById(String routeId);
  Future<List<Route>> getRoutesByDriverId(String driverId);
  Future<List<Route>> getAllRoutes();
  Future<void> deleteRoute(String routeId);
  Future<void> clearAllRoutes();
}

class InMemoryRouteRepository implements RouteRepository {
  final Map<String, Route> _routes = {};
  final Map<String, List<String>> _driverRoutes = {};

  @override
  Future<Route> createRoute(Route route) async {
    try {
      _routes[route.id] = route;

      // Add to driver's route list
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
      if (e is DatabaseFailure) {
        rethrow;
      }
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
      if (route == null) {
        throw const DatabaseFailure('Route not found');
      }

      // Remove from routes
      _routes.remove(routeId);

      // Remove from driver's route list
      _driverRoutes[route.driverId]?.remove(routeId);

      // Clean up empty driver entries
      if (_driverRoutes[route.driverId]?.isEmpty == true) {
        _driverRoutes.remove(route.driverId);
      }
    } catch (e) {
      if (e is DatabaseFailure) {
        rethrow;
      }
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

  // Helper methods for testing and debugging
  int get routeCount => _routes.length;
  int get driverCount => _driverRoutes.length;

  List<String> getDriverIds() {
    return _driverRoutes.keys.toList();
  }

  List<String> getRouteIds() {
    return _routes.keys.toList();
  }
}
