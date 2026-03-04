import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/route_tracking_bloc.dart';
import '../bloc/route_tracking_event.dart';
import '../bloc/route_tracking_state.dart';
import '../services/location_service.dart';
import '../widgets/gps_dialogs.dart';
import '../../../core/constants/app_constants.dart';

class RouteTrackingPage extends StatelessWidget {
  const RouteTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: BlocBuilder<RouteTrackingBloc, RouteTrackingState>(
        builder: (context, state) {
          return _buildBody(context, state);
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildBody(BuildContext context, RouteTrackingState state) {
    if (state is RouteTrackingInitial) {
      return _buildInitialState(context);
    } else if (state is RouteTrackingLoading) {
      return _buildLoadingState();
    } else if (state is RouteTrackingInProgress) {
      return _buildInProgressState(context, state);
    } else if (state is RouteTrackingPaused) {
      return _buildPausedState(context, state);
    } else if (state is RouteTrackingCompleted) {
      return _buildCompletedState(context, state);
    } else if (state is RouteTrackingLoaded) {
      return _buildLoadedState(context, state);
    } else if (state is RouteTrackingError) {
      return _buildErrorState(context, state);
    } else {
      return _buildInitialState(context);
    }
  }

  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Bienvenido a ${AppConstants.appName}',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Gestiona tus rutas con seguimiento de geolocalización en tiempo real',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => _startNewRoute(context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar Nueva Ruta'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Procesando...'),
        ],
      ),
    );
  }

  Widget _buildInProgressState(
    BuildContext context,
    RouteTrackingInProgress state,
  ) {
    final route = state.currentRoute;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(
            context,
            'Ruta en Progreso',
            Colors.green,
            Icons.directions_car,
          ),
          const SizedBox(height: 16),
          _buildRouteStatsCard(context, route),
          const SizedBox(height: 16),
          _buildRecentLocationsCard(context, route.points),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pauseRoute(context),
                  icon: const Icon(Icons.pause),
                  label: const Text('Pausar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _endRoute(context),
                  icon: const Icon(Icons.stop),
                  label: const Text('Finalizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPausedState(BuildContext context, RouteTrackingPaused state) {
    final route = state.currentRoute;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(
            context,
            'Ruta Pausada',
            Colors.orange,
            Icons.pause_circle,
          ),
          const SizedBox(height: 16),
          _buildRouteStatsCard(context, route),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _resumeRoute(context),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Reanudar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _endRoute(context),
                  icon: const Icon(Icons.stop),
                  label: const Text('Finalizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedState(
    BuildContext context,
    RouteTrackingCompleted state,
  ) {
    final route = state.completedRoute;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(
            context,
            'Ruta Completada',
            Colors.blue,
            Icons.check_circle,
          ),
          const SizedBox(height: 16),
          _buildRouteStatsCard(context, route),
          const SizedBox(height: 16),
          _buildRecentLocationsCard(context, route.points),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startNewRoute(context),
              icon: const Icon(Icons.add),
              label: const Text('Iniciar Nueva Ruta'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, RouteTrackingLoaded state) {
    return _buildRouteDetails(context, state.route);
  }

  Widget _buildErrorState(BuildContext context, RouteTrackingError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorMessage(state.message),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorDescription(state.message),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _retryStartRoute(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
                if (state.message.contains('GPS') ||
                    state.message.contains('disabled'))
                  TextButton.icon(
                    onPressed: () => _openLocationSettings(context),
                    icon: const Icon(Icons.settings),
                    label: const Text('Configurar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(String message) {
    if (message.contains('GPS') || message.contains('disabled')) {
      return 'GPS Desactivado';
    } else if (message.contains('permission')) {
      return 'Permisos Requeridos';
    } else {
      return 'Error';
    }
  }

  String _getErrorDescription(String message) {
    if (message.contains('GPS') || message.contains('disabled')) {
      return 'El GPS está desactivado. Actívalo para usar el seguimiento de rutas.';
    } else if (message.contains('permission')) {
      return 'La aplicación necesita permisos de ubicación para funcionar correctamente.';
    } else {
      return message;
    }
  }

  Future<void> _retryStartRoute(BuildContext context) async {
    _startNewRoute(context);
  }

  Future<void> _openLocationSettings(BuildContext context) async {
    try {
      final locationService = LocationService();
      await locationService.openLocationSettings();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRouteDetails(BuildContext context, dynamic route) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(
            context,
            'Detalles de Ruta',
            Theme.of(context).colorScheme.primary,
            Icons.info,
          ),
          const SizedBox(height: 16),
          _buildRouteStatsCard(context, route),
          const SizedBox(height: 16),
          _buildRecentLocationsCard(context, route.points),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    String title,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStatsCard(BuildContext context, dynamic route) {
    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estadísticas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Tiempo',
                    _formatDuration(route.duration),
                    Icons.access_time,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Distancia',
                    '${route.totalDistance.toStringAsFixed(2)} m',
                    Icons.straighten,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Puntos',
                    '${route.points.length}',
                    Icons.location_on,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Estado',
                    route.status.displayName,
                    Icons.info_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildRecentLocationsCard(BuildContext context, List points) {
    final recentPoints = points.length > 5
        ? points.reversed.take(5).toList()
        : points.reversed.toList();

    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ubicaciones Recientes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (points.isEmpty)
              const Text('No hay puntos de ubicación registrados')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentPoints.length,
                itemBuilder: (context, index) {
                  final point = recentPoints[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(
                      '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                    ),
                    subtitle: Text(_formatDateTime(point.timestamp)),
                    trailing: point.speed != null
                        ? Text('${point.speed!.toStringAsFixed(1)} m/s')
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    return BlocBuilder<RouteTrackingBloc, RouteTrackingState>(
      builder: (context, state) {
        if (state is RouteTrackingInitial || state is RouteTrackingError) {
          return FloatingActionButton.extended(
            onPressed: () => _startNewRoute(context),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Ruta'),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _startNewRoute(BuildContext context) async {
    context.read<RouteTrackingBloc>().add(const StartRoute('driver_001'));
  }

  void _pauseRoute(BuildContext context) {
    context.read<RouteTrackingBloc>().add(const PauseRoute());
  }

  void _resumeRoute(BuildContext context) {
    context.read<RouteTrackingBloc>().add(const ResumeRoute());
  }

  void _endRoute(BuildContext context) {
    context.read<RouteTrackingBloc>().add(const EndRoute());
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
