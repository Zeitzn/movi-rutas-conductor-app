import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

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
      // En flutter_foreground_task v8, el dato puede llegar como String
      // o ya decodificado como Map según la versión del platform channel.
      final Map<String, dynamic> json;
      if (data is String) {
        json = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map) {
        json = Map<String, dynamic>.from(data);
      } else {
        debugPrint('⚠️ onTaskData: unexpected data type ${data.runtimeType}');
        return;
      }

      if (json['type'] == 'location') {
        _locationController.add(json);
      }
    } catch (e) {
      debugPrint('⚠️ onTaskData error: $e — data: $data');
    }
  }

  /// Clean up resources. Call on app dispose.
  static void dispose() {
    _locationController.close();
  }
}
