enum RouteStatus {
  initial,
  inProgress,
  paused,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case RouteStatus.initial:
        return 'Inicial';
      case RouteStatus.inProgress:
        return 'En Progreso';
      case RouteStatus.paused:
        return 'Pausada';
      case RouteStatus.completed:
        return 'Completada';
      case RouteStatus.cancelled:
        return 'Cancelada';
    }
  }
}
