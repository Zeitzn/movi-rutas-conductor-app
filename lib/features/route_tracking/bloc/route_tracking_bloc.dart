import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/background_communication_service.dart';
import '../models/route.dart';
import '../models/route_point.dart';
import '../models/route_status.dart';
import '../repositories/route_repository.dart';
import '../services/location_service.dart';
import '../services/background_tracking_handler.dart';
import 'route_tracking_event.dart';
import 'route_tracking_state.dart';

class RouteTrackingBloc extends Bloc<RouteTrackingEvent, RouteTrackingState> {
  final RouteRepository _routeRepository;
  final LocationService _locationService;

  StreamSubscription<Map<String, dynamic>>? _backgroundSubscription;
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
  }

  Future<void> _onStartRoute(
    StartRoute event,
    Emitter<RouteTrackingState> emit,
  ) async {
    emit(const RouteTrackingLoading());

    try {
      // Check permissions — lanza PermissionFailure si falta algo
      await _locationService.hasLocationPermission();

      // Create new route
      final newRoute = Route(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        driverId: event.driverId,
        startTime: DateTime.now(),
        status: RouteStatus.inProgress,
      );

      _currentRoute = await _routeRepository.createRoute(newRoute);

      // Obtener ubicación actual inmediatamente para que el card
      // "En curso" muestre el primer envío sin demora
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final initialPoint = RoutePoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
        speed: position.speed,
        accuracy: position.accuracy,
        altitude: position.altitude,
      );

      _currentRoute = _currentRoute!.copyWith(points: [initialPoint]);
      _currentRoute = await _routeRepository.updateRoute(_currentRoute!);

      // Start foreground task: mantiene WebSocket + location stream + notificación
      // aunque la app esté en background o la pantalla apagada
      await FlutterForegroundTask.startService(
        notificationTitle: AppConstants.appName,
        notificationText: 'Ruta en curso — enviando ubicación',
        callback: startCallback,
      );

      // Emitir ANTES de suscribirse a los streams para evitar el race condition:
      // si una ubicación llega antes del emit, el guard "state is RouteTrackingInProgress"
      // en _onUpdateLocation fallaría y la actualización se perdería.
      emit(RouteTrackingInProgress(_currentRoute!));

      // Fuente 1 (principal): ubicaciones que vienen del foreground task via
      // sendDataToMain → BackgroundCommunicationService. Se actualiza CADA
      // VEZ que el background task envía ubicación al WebSocket.
      _backgroundSubscription =
          BackgroundCommunicationService.locationStream.listen(
        (data) {
          final routePoint = RoutePoint(
            latitude: (data['latitude'] as num).toDouble(),
            longitude: (data['longitude'] as num).toDouble(),
            timestamp: data['timestamp'] != null
                ? DateTime.parse(data['timestamp'] as String)
                : DateTime.now(),
            speed: (data['speed'] as num?)?.toDouble(),
            accuracy: (data['accuracy'] as num?)?.toDouble(),
            altitude: (data['altitude'] as num?)?.toDouble(),
          );
          add(UpdateLocation(routePoint));
        },
      );

      // Fuente 2 (fallback): stream de ubicación directo desde el main isolate.
      // Si el puente sendDataToMain falla, el stream local garantiza que la UI
      // se actualice. La deduplicación en _onUpdateLocation evita puntos dobles.
      _locationSubscription = _locationService.getLocationStream().listen(
        (position) {
          final routePoint = RoutePoint(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: position.timestamp,
            speed: position.speed,
            accuracy: position.accuracy,
            altitude: position.altitude,
          );
          add(UpdateLocation(routePoint));
        },
      );
    } catch (e) {
      final msg = e is Failure ? e.message : 'Error al iniciar la ruta';
      emit(RouteTrackingError(msg));
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
      // Avisar al foreground task que pause los envíos al WS
      FlutterForegroundTask.sendDataToTask('pause');
      // El task handler actualiza la notificación automáticamente

      final updatedRoute = _currentRoute!.copyWith(
        status: RouteStatus.paused,
        duration: DateTime.now().difference(_currentRoute!.startTime).inSeconds,
      );

      _currentRoute = await _routeRepository.updateRoute(updatedRoute);

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
      // Avisar al foreground task que reanude los envíos
      FlutterForegroundTask.sendDataToTask('resume');

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
      // Cancel all subscriptions
      await _backgroundSubscription?.cancel();
      _backgroundSubscription = null;
      await _locationSubscription?.cancel();
      _locationSubscription = null;

      // Detener el foreground task (desconecta WS + cancela location stream)
      await FlutterForegroundTask.stopService();

      final endTime = DateTime.now();
      final duration = endTime.difference(_currentRoute!.startTime).inSeconds;

      final updatedRoute = _currentRoute!.copyWith(
        status: RouteStatus.completed,
        endTime: endTime,
        duration: duration,
      );

      _currentRoute = await _routeRepository.updateRoute(updatedRoute);
      _currentRoute = null;

      emit(const RouteTrackingInitial());
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

    // Deduplicación: si el timestamp del nuevo punto está a menos de 500ms
    // del último punto registrado, es el mismo fix GPS llegando desde dos
    // streams (background task + main isolate). Lo ignoramos.
    if (_currentRoute!.points.isNotEmpty) {
      final lastTs = _currentRoute!.points.last.timestamp;
      if (event.routePoint.timestamp
          .difference(lastTs)
          .inMilliseconds
          .abs() < 500) {
        return;
      }
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

      // NOTA: el envío al WebSocket lo maneja el foreground task
      // NOTA: la notificación la actualiza el BackgroundTrackingHandler

      emit(RouteTrackingInProgress(_currentRoute!));
    } catch (e) {
      emit(RouteTrackingError('Failed to update location: $e'));
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
    _backgroundSubscription?.cancel();
    _locationSubscription?.cancel();
    return super.close();
  }
}
