import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../models/route.dart';
import '../models/route_point.dart';
import '../models/route_status.dart';
import '../repositories/route_repository.dart';
import '../services/location_service.dart';
import '../services/background_location_service.dart';
import 'route_tracking_event.dart';
import 'route_tracking_state.dart';

class RouteTrackingBloc extends Bloc<RouteTrackingEvent, RouteTrackingState> {
  final RouteRepository _routeRepository;
  final LocationService _locationService;

  StreamSubscription<Position>? _locationSubscription;
  Route? _currentRoute;

  RouteTrackingBloc({
    required RouteRepository routeRepository,
    required LocationService locationService,
  }) : _routeRepository = routeRepository,
       _locationService = locationService,
       super(const RouteTrackingInitial()) {
    on<StartRoute>(_onStartRoute);
    on<PauseRoute>(_onPauseRoute);
    on<ResumeRoute>(_onResumeRoute);
    on<EndRoute>(_onEndRoute);
    on<UpdateLocation>(_onUpdateLocation);
    on<LoadRoute>(_onLoadRoute);
    on<RefreshRouteStatus>(_onRefreshRouteStatus);
  }

  Future<void> _onStartRoute(
    StartRoute event,
    Emitter<RouteTrackingState> emit,
  ) async {
    emit(const RouteTrackingLoading());

    try {
      // Check permissions
      final hasPermission = await _locationService.hasLocationPermission();
      if (!hasPermission) {
        emit(const RouteTrackingError('Location permissions are required'));
        return;
      }

      // Create new route
      final newRoute = Route(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        driverId: event.driverId,
        startTime: DateTime.now(),
        status: RouteStatus.inProgress,
      );

      _currentRoute = await _routeRepository.createRoute(newRoute);

      // Iniciar notificación de foreground
      await BackgroundLocationService.startForegroundNotification();

      // Start location tracking
      _locationSubscription = _locationService.getLocationStream().listen(
        (position) {
          final routePoint = RoutePoint(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
            speed: position.speed,
            accuracy: position.accuracy,
            altitude: position.altitude,
          );
          add(UpdateLocation(routePoint));
        },
        onError: (error) {
          emit(RouteTrackingError('Location tracking error: $error'));
        },
      );

      emit(RouteTrackingInProgress(_currentRoute!));
    } catch (e) {
      emit(RouteTrackingError('Failed to start route: $e'));
    }
  }

  Future<void> _onPauseRoute(
    PauseRoute event,
    Emitter<RouteTrackingState> emit,
  ) async {
    if (_currentRoute == null) {
      emit(const RouteTrackingError('No active route to pause'));
      return;
    }

    try {
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      final updatedRoute = _currentRoute!.copyWith(
        status: RouteStatus.paused,
        duration: DateTime.now().difference(_currentRoute!.startTime).inSeconds,
      );

      _currentRoute = await _routeRepository.updateRoute(updatedRoute);
      // Actualizar notificación de foreground
      await BackgroundLocationService.updateNotificationStatus(
        RouteStatus.paused,
        _currentRoute!.points.length,
      );

      emit(RouteTrackingPaused(_currentRoute!));
    } catch (e) {
      emit(RouteTrackingError('Failed to pause route: $e'));
    }
  }

  Future<void> _onResumeRoute(
    ResumeRoute event,
    Emitter<RouteTrackingState> emit,
  ) async {
    if (_currentRoute == null || _currentRoute!.status != RouteStatus.paused) {
      emit(const RouteTrackingError('No paused route to resume'));
      return;
    }

    try {
      // Restart location tracking
      _locationSubscription = _locationService.getLocationStream().listen(
        (position) {
          final routePoint = RoutePoint(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
            speed: position.speed,
            accuracy: position.accuracy,
            altitude: position.altitude,
          );
          add(UpdateLocation(routePoint));
        },
        onError: (error) {
          emit(RouteTrackingError('Location tracking error: $error'));
        },
      );

      final updatedRoute = _currentRoute!.copyWith(
        status: RouteStatus.inProgress,
      );

      _currentRoute = await _routeRepository.updateRoute(updatedRoute);
      emit(RouteTrackingInProgress(_currentRoute!));
    } catch (e) {
      emit(RouteTrackingError('Failed to resume route: $e'));
    }
  }

  Future<void> _onEndRoute(
    EndRoute event,
    Emitter<RouteTrackingState> emit,
  ) async {
    if (_currentRoute == null) {
      emit(const RouteTrackingError('No active route to end'));
      return;
    }

    try {
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      final endTime = DateTime.now();
      final duration = endTime.difference(_currentRoute!.startTime).inSeconds;

      final updatedRoute = _currentRoute!.copyWith(
        status: RouteStatus.completed,
        endTime: endTime,
        duration: duration,
      );

      _currentRoute = await _routeRepository.updateRoute(updatedRoute);
      // Detener notificación de foreground
      await BackgroundLocationService.stopForegroundNotification();

      emit(RouteTrackingCompleted(_currentRoute!));
    } catch (e) {
      emit(RouteTrackingError('Failed to end route: $e'));
    }
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<RouteTrackingState> emit,
  ) async {
    if (_currentRoute == null ||
        _currentRoute!.status != RouteStatus.inProgress) {
      return;
    }

    try {
      final updatedPoints = List<RoutePoint>.from(_currentRoute!.points)
        ..add(event.routePoint);

      // Calculate total distance
      double totalDistance = _currentRoute!.totalDistance;
      if (_currentRoute!.points.isNotEmpty) {
        final lastPoint = _currentRoute!.points.last;
        totalDistance += _calculateDistance(
          lastPoint.latitude,
          lastPoint.longitude,
          event.routePoint.latitude,
          event.routePoint.longitude,
        );
      }

      final updatedRoute = _currentRoute!.copyWith(
        points: updatedPoints,
        totalDistance: totalDistance,
        duration: DateTime.now().difference(_currentRoute!.startTime).inSeconds,
      );

      _currentRoute = await _routeRepository.updateRoute(updatedRoute);

      // Emit current state with updated route
      if (state is RouteTrackingInProgress) {
        // Actualizar notificación con nuevo punto
        await BackgroundLocationService.updateNotificationStatus(
          RouteStatus.inProgress,
          _currentRoute!.points.length,
        );

        emit(RouteTrackingInProgress(_currentRoute!));
      }
    } catch (e) {
      emit(RouteTrackingError('Failed to update location: $e'));
    }
  }

  Future<void> _onLoadRoute(
    LoadRoute event,
    Emitter<RouteTrackingState> emit,
  ) async {
    emit(const RouteTrackingLoading());

    try {
      final route = await _routeRepository.getRouteById(event.routeId);
      if (route != null) {
        _currentRoute = route;
        emit(RouteTrackingLoaded(route));
      } else {
        emit(RouteTrackingError('Route not found: ${event.routeId}'));
      }
    } catch (e) {
      emit(RouteTrackingError('Failed to load route: $e'));
    }
  }

  Future<void> _onRefreshRouteStatus(
    RefreshRouteStatus event,
    Emitter<RouteTrackingState> emit,
  ) async {
    if (_currentRoute == null) {
      emit(const RouteTrackingError('No route to refresh'));
      return;
    }

    try {
      final route = await _routeRepository.getRouteById(_currentRoute!.id);
      if (route != null) {
        _currentRoute = route;

        switch (route.status) {
          case RouteStatus.inProgress:
            emit(RouteTrackingInProgress(route));
            break;
          case RouteStatus.paused:
            emit(RouteTrackingPaused(route));
            break;
          case RouteStatus.completed:
            emit(RouteTrackingCompleted(route));
            break;
          default:
            emit(RouteTrackingLoaded(route));
        }
      }
    } catch (e) {
      emit(RouteTrackingError('Failed to refresh route status: $e'));
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
