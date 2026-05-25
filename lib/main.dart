import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:workmanager/workmanager.dart';

import 'core/constants/app_constants.dart';
import 'core/services/background_communication_service.dart';

import 'features/route_tracking/bloc/route_tracking_bloc.dart';
import 'features/route_tracking/pages/route_tracking_page.dart';
import 'features/route_tracking/repositories/route_repository.dart';
import 'features/route_tracking/services/location_service.dart';
import 'features/route_tracking/services/background_location_service.dart';
import 'features/route_tracking/services/websocket_service.dart';

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/services/auth_service.dart';

// WorkManager callback function (fallback for periodic tasks)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final backgroundService = BackgroundLocationService();
      await backgroundService.initializeBackgroundTask();

      final position = await backgroundService
          .getCurrentLocationForBackground();

      if (position != null) {
        await backgroundService.saveLocationPoint(position);

        final wsService = WebSocketService();
        await wsService.connect();
        await wsService.sendLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        );
      }

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutter_foreground_task for background location tracking
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'route_tracking_channel',
      channelName: 'Route Tracking',
      channelDescription: 'Tracks your route in real-time',
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  // Register callback for data coming from the foreground task isolate
  FlutterForegroundTask.addTaskDataCallback(
    BackgroundCommunicationService.onTaskData,
  );

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
        RepositoryProvider<IAuthRepository>(
          create: (context) => SharedPrefsAuthRepository(),
        ),
        RepositoryProvider<AuthService>(
          create: (context) => AuthService(),
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
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<IAuthRepository>(),
              authService: context.read<AuthService>(),
            )..add(const CheckAuthStatus()),
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
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return const RouteTrackingPage();
              }
              return const LoginPage();
            },
          ),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
