import 'package:equatable/equatable.dart';
import '../models/route_point.dart';

abstract class RouteTrackingEvent extends Equatable {
  const RouteTrackingEvent();

  @override
  List<Object?> get props => [];
}

class StartRoute extends RouteTrackingEvent {
  final String driverId;

  const StartRoute(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

class PauseRoute extends RouteTrackingEvent {
  const PauseRoute();
}

class ResumeRoute extends RouteTrackingEvent {
  const ResumeRoute();
}

class EndRoute extends RouteTrackingEvent {
  const EndRoute();
}

class UpdateLocation extends RouteTrackingEvent {
  final RoutePoint routePoint;

  const UpdateLocation(this.routePoint);

  @override
  List<Object?> get props => [routePoint];
}

class LoadRoute extends RouteTrackingEvent {
  final String routeId;

  const LoadRoute(this.routeId);

  @override
  List<Object?> get props => [routeId];
}

class RefreshRouteStatus extends RouteTrackingEvent {
  const RefreshRouteStatus();
}
