class AppConstants {
  static const String appName = 'Movi Rutas';
  static const String appVersion = '1.0.0';

  // Location settings
  static const double defaultLocationAccuracy = 100.0;
  static const int locationUpdateInterval = 5000; // 5 seconds
  static const double minDistanceBetweenUpdates = 10.0; // 10 meters

  // Background service settings
  static const String backgroundTaskName = 'locationTrackingTask';
  static const int backgroundTaskInterval = 15; // 15 minutes
  static const String notificationChannelId = 'route_tracking_channel';
  static const String notificationChannelName = 'Route Tracking';
  static const String notificationChannelDescription =
      'Tracks your route in real-time';

  // WebSocket settings
  static const String websocketUrl = 'ws://your-websocket-server.com/ws';
  static const int websocketReconnectDelay = 3000; // 3 seconds

  // Data storage
  static const String routesBoxName = 'routes';
  static const String settingsBoxName = 'settings';

  // UI constants
  static const double defaultPadding = 16.0;
  static const double cardElevation = 4.0;
  static const double borderRadius = 12.0;
}
