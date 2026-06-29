import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/route_tracking_bloc.dart';
import '../bloc/route_tracking_event.dart';
import '../bloc/route_tracking_state.dart';
import '../services/location_service.dart';
import '../../../core/constants/app_constants.dart';

class RouteTrackingPage extends StatelessWidget {
  const RouteTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final username = authState is AuthAuthenticated
        ? authState.token.username?.toUpperCase() ?? 'Usuario'
        : 'Iniciar sesión';

    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: BlocBuilder<RouteTrackingBloc, RouteTrackingState>(
        builder: (context, state) {
          return _buildBody(context, state);
        },
      ),
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
    final lastPoint = route.points.isNotEmpty ? route.points.last : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Último envío — fecha y hora bien visible
          Card(
            elevation: AppConstants.cardElevation,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 12, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'EN CURSO',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.green.shade700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Último envío',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lastPoint != null
                        ? _formatTime(lastPoint.timestamp)
                        : '--:--:--',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (lastPoint != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(lastPoint.timestamp),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (lastPoint != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      child: Text(
                        '${lastPoint.latitude.toStringAsFixed(6)}, ${lastPoint.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Botones de acción
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
    } else if (message.contains('Permiso') || message.contains('permission')) {
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
    } else if (message.contains('todo el tiempo') ||
        message.contains('Allow all')) {
      return message;
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

  Future<void> _startNewRoute(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    final driverId = authState is AuthAuthenticated
        ? (authState.token.username ?? 'unknown')
        : 'unknown';
    context.read<RouteTrackingBloc>().add(StartRoute(driverId));
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

  /// Cerrar sesión: primero finaliza la ruta activa (libera GPS, cierra
  /// WebSocket, detiene el foreground task) y luego limpia la autenticación.
  Future<void> _logout(BuildContext context) async {
    // Finalizar ruta si hay una activa — el handler internamente checkea null
    context.read<RouteTrackingBloc>().add(const EndRoute());

    // Pequeña pausa para que el EndRoute procese el stop del foreground task
    // antes de navegar al login (no bloqueante para el usuario).
    await Future.delayed(const Duration(milliseconds: 300));

    if (context.mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

}
