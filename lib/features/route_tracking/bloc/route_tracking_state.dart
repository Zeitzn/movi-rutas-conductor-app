import 'package:equatable/equatable.dart';
import '../models/route.dart';
import '../models/route_status.dart';

abstract class RouteTrackingState extends Equatable {
  const RouteTrackingState();

  @override
  List<Object?> get props => [];
}

class RouteTrackingInitial extends RouteTrackingState {
  const RouteTrackingInitial();
}

class RouteTrackingLoading extends RouteTrackingState {
  const RouteTrackingLoading();
}

class RouteTrackingInProgress extends RouteTrackingState {
  final Route currentRoute;

  const RouteTrackingInProgress(this.currentRoute);

  @override
  List<Object?> get props => [currentRoute];
}

class RouteTrackingPaused extends RouteTrackingState {
  final Route currentRoute;

  const RouteTrackingPaused(this.currentRoute);

  @override
  List<Object?> get props => [currentRoute];
}

class RouteTrackingError extends RouteTrackingState {
  final String message;
  final RouteStatus? previousStatus;

  const RouteTrackingError(this.message, {this.previousStatus});

  @override
  List<Object?> get props => [message, previousStatus];
}
