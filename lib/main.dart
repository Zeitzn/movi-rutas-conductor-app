import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';
import 'features/route_tracking/bloc/route_tracking_bloc.dart';
import 'features/route_tracking/pages/route_tracking_page.dart';
import 'features/route_tracking/repositories/route_repository.dart';
import 'features/route_tracking/services/location_service.dart';
import 'features/route_tracking/services/background_location_service.dart';
import 'core/constants/app_constants.dart';

// WorkManager callback function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize background location service
      final backgroundService = BackgroundLocationService();
      await backgroundService.initializeBackgroundTask();

      // Get current location
      final position = await backgroundService
          .getCurrentLocationForBackground();

      if (position != null) {
        // Save location point
        await backgroundService.saveLocationPoint(position);

        // Send to WebSocket (if needed)
        await backgroundService.sendLocationToWebSocket(position);
      }

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager for background tasks
  await Workmanager().initialize(callbackDispatcher);

  runApp(const MoviRutasApp());
}

class MoviRutasApp extends StatelessWidget {
  const MoviRutasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<RouteRepository>(
          create: (context) => InMemoryRouteRepository(),
        ),
        RepositoryProvider<LocationService>(
          create: (context) => LocationService(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<RouteTrackingBloc>(
            create: (context) => RouteTrackingBloc(
              routeRepository: context.read<RouteRepository>(),
              locationService: context.read<LocationService>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
            cardTheme: CardThemeData(
              elevation: AppConstants.cardElevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
          home: const RouteTrackingPage(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

