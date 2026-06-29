import 'package:flutter_test/flutter_test.dart';
import 'package:movi_rutas_example/features/route_tracking/models/route_point.dart';

void main() {
  group('RoutePoint roundtrip', () {
    test('toJson/fromJson with all fields populated', () {
      final original = RoutePoint(
        latitude: -34.603722,
        longitude: -58.381592,
        timestamp: DateTime.parse('2026-06-28T10:30:00.000Z'),
        speed: 12.5,
        accuracy: 8.0,
        altitude: 25.0,
      );

      final json = original.toJson();
      final reconstructed = RoutePoint.fromJson(json);

      expect(reconstructed, equals(original));
    });

    test('toJson/fromJson with nullable fields as null', () {
      final original = RoutePoint(
        latitude: -34.603722,
        longitude: -58.381592,
        timestamp: DateTime.parse('2026-06-28T10:30:00.000Z'),
        speed: null,
        accuracy: null,
        altitude: null,
      );

      final json = original.toJson();
      final reconstructed = RoutePoint.fromJson(json);

      expect(reconstructed, equals(original));
    });
  });
}
