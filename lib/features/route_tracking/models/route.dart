import 'package:equatable/equatable.dart';
import 'route_point.dart';
import 'route_status.dart';

class Route extends Equatable {
  final String id;
  final String driverId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<RoutePoint> points;
  final RouteStatus status;
  final double totalDistance;
  final int duration;

  const Route({
    required this.id,
    required this.driverId,
    required this.startTime,
    this.endTime,
    this.points = const [],
    required this.status,
    this.totalDistance = 0.0,
    this.duration = 0,
  });

  Route copyWith({
    String? id,
    String? driverId,
    DateTime? startTime,
    DateTime? endTime,
    List<RoutePoint>? points,
    RouteStatus? status,
    double? totalDistance,
    int? duration,
  }) {
    return Route(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      points: points ?? this.points,
      status: status ?? this.status,
      totalDistance: totalDistance ?? this.totalDistance,
      duration: duration ?? this.duration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'points': points.map((point) => point.toJson()).toList(),
      'status': status.name,
      'totalDistance': totalDistance,
      'duration': duration,
    };
  }

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      points: (json['points'] as List<dynamic>)
          .map((point) => RoutePoint.fromJson(point as Map<String, dynamic>))
          .toList(),
      status: RouteStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RouteStatus.initial,
      ),
      totalDistance: (json['totalDistance'] as num).toDouble(),
      duration: json['duration'] as int,
    );
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    startTime,
    endTime,
    points,
    status,
    totalDistance,
    duration,
  ];

  @override
  String toString() {
    return 'Route(id: $id, driverId: $driverId, startTime: $startTime, endTime: $endTime, status: $status, totalDistance: $totalDistance, duration: $duration, points: ${points.length})';
  }
}
