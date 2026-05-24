# Estado global — flutter_bloc + equatable

## Dependencias

```yaml
dependencies:
  flutter_bloc: ^9.1.1
  equatable: ^2.0.7
```

## Eventos

Un evento por acción. Todos extienden `Equatable` para comparación.

```dart
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
```

### Reglas
- Eventos sin datos usan `const` constructor vacío.
- Eventos con datos inmutables (`final`).
- `props` incluye todos los campos para comparación.

## Estados

Un estado por situación posible. No usar `enum` + switch dentro del estado.

```dart
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

class RouteTrackingError extends RouteTrackingState {
  final String message;
  final RouteStatus? previousStatus;

  const RouteTrackingError(this.message, {this.previousStatus});

  @override
  List<Object?> get props => [message, previousStatus];
}
```

### Reglas
- Estado `Loading` para operaciones asíncronas.
- Estado `Error` con `message` y campo opcional `previousStatus` para recuperación.
- Cada estado posible tiene su propia clase.
- Estados con datos reciben los datos en el constructor.

## BLoC

```dart
class RouteTrackingBloc extends Bloc<RouteTrackingEvent, RouteTrackingState> {
  final RouteRepository _routeRepository;
  final LocationService _locationService;

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
      // ... lógica ...
      emit(RouteTrackingInProgress(_currentRoute!));
    } catch (e) {
      emit(RouteTrackingError('Failed to start route: $e'));
    }
  }
}
```

### Reglas
- **Inyección por constructor.** No crear services/repos dentro del BLoC.
- Cada `on<Evento>` tiene su handler privado `_onNombreEvento`.
- Cancelar suscripciones (`StreamSubscription`) en `close()`.
- No emitir desde catch genérico sin emitir estado de error.
- `close()` debe limpiar suscripciones antes de llamar `super.close()`:

```dart
@override
Future<void> close() {
  _locationSubscription?.cancel();
  return super.close();
}
```

## Registro en el árbol

```dart
MultiBlocProvider(
  providers: [
    BlocProvider<RouteTrackingBloc>(
      create: (context) => RouteTrackingBloc(
        routeRepository: context.read<RouteRepository>(),
        locationService: context.read<LocationService>(),
      ),
    ),
  ],
  child: MaterialApp(...),
)
```

No usar `context.watch` directo. Usar `BlocBuilder` o `BlocSelector`.
