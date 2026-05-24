# Modelos de dominio

## Estructura base

Todos los modelos extienden `Equatable` para comparación por valor e implementan serialización JSON.

```dart
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
  // ...
}
```

## Métodos requeridos

### `copyWith`

```dart
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
```

### `toJson`

```dart
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
```

### `fromJson` (factory)

```dart
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
```

### `props`

```dart
@override
List<Object?> get props => [
  id, driverId, startTime, endTime, points, status, totalDistance, duration,
];
```

### `toString`

```dart
@override
String toString() {
  return 'Route(id: $id, driverId: $driverId, startTime: $startTime, ...)';
}
```

## Enums con display name

```dart
enum RouteStatus {
  initial,
  inProgress,
  paused,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case RouteStatus.initial:     return 'Inicial';
      case RouteStatus.inProgress:  return 'En Progreso';
      case RouteStatus.paused:      return 'Pausada';
      case RouteStatus.completed:   return 'Completada';
      case RouteStatus.cancelled:   return 'Cancelada';
    }
  }
}
```

## Reglas

- Propiedades **inmutables** (`final`).
- Valores por defecto en el constructor (`const []`, `0.0`, `0`).
- **Tipos explícitos.** No usar `dynamic`. Si viene de JSON con `num`, castear con `.toDouble()`.
- Campos opcionales tipados con `?` (`DateTime?`, `double?`).
- Ubicación: `features/<feature>/models/`.
