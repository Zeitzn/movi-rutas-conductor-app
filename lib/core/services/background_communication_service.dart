import 'dart:async';
import 'dart:convert';

/// Bridge between the main isolate and the foreground task isolate.
///
/// The [BackgroundTrackingHandler] in the background isolate sends location
/// data via [FlutterForegroundTask.sendDataToMain], which arrives here
/// through [onTaskData] and is forwarded to the [RouteTrackingBloc] via
/// the [locationStream].
class BackgroundCommunicationService {
  static final StreamController<Map<String, dynamic>> _locationController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of location data coming from the background foreground task.
  static Stream<Map<String, dynamic>> get locationStream =>
      _locationController.stream;

  /// Called from main.dart when the foreground task sends data.
  static void onTaskData(Object data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      if (json['type'] == 'location') {
        _locationController.add(json);
      }
    } catch (_) {
      // Ignore malformed data
    }
  }

  /// Clean up resources. Call on app dispose.
  static void dispose() {
    _locationController.close();
  }
}
