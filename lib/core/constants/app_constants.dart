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

  static const String websocketUrl = 'ws://mr.dev.todoprogramacionapi.xyz/channels';
  static const int websocketReconnectDelay = 5000; // 5 seconds
  static const String websocketTopic = '/topic/channel/PE/AYAC/001';
  static const String websocketDestination = '/app/channel/PE/AYAC/001';

  // WebSocket message format for GPS coordinates
  static const String websocketRemitente = 'conductor_app';

  // Data storage
  static const String routesBoxName = 'routes';
  static const String settingsBoxName = 'settings';

  // Auth settings
  static const String authHost = 'https://keycloak.todoprogramacionapi.xyz/realms/movi-rutas-prod/protocol/openid-connect';
  static const String authTokenEndpoint = '/token';
  static const String authClientId = 'movi-rutas-core-api-rest-client';
  static const String authClientSecret = 'BWwkPsHgu4pcLhjEmqq4J775Tkp1hnKS';
  static const String authGrantType = 'password';
  static const String authRefreshGrantType = 'refresh_token';

  // UI constants
  static const double defaultPadding = 16.0;
  static const double cardElevation = 4.0;
  static const double borderRadius = 12.0;
}
