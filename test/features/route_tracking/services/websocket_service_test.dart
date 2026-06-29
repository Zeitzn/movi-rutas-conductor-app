import 'package:flutter_test/flutter_test.dart';
import 'package:movi_rutas_example/features/route_tracking/services/websocket_service.dart';

void main() {
  group('WebSocketService topic/destination', () {
    test('builds correct topic and destination with given companyUuid', () {
      const companyUuid = '550e8400-e29b-41d4-a716-446655440000';
      final service = WebSocketService(companyUuid: companyUuid);

      expect(
        service.topic,
        '/topic/channel/PE/AYAC/550e8400-e29b-41d4-a716-446655440000',
      );
      expect(
        service.destination,
        '/app/channel/PE/AYAC/550e8400-e29b-41d4-a716-446655440000',
      );
    });

    test('empty companyUuid produces topic/destination trailing slash', () {
      final service = WebSocketService(companyUuid: '');

      expect(service.topic, '/topic/channel/PE/AYAC/');
      expect(service.destination, '/app/channel/PE/AYAC/');
    });

    test('companyUuid defaults to empty string', () {
      final service = WebSocketService();

      expect(service.companyUuid, '');
      expect(service.topic, '/topic/channel/PE/AYAC/');
    });

    test('connect() skips connection when companyUuid is empty', () async {
      final service = WebSocketService(companyUuid: '');
      // Should not throw, should just log and return
      await service.connect();
      expect(service.isConnected, false);
    });

    test('different companyUuids produce different destinations', () {
      final serviceA = WebSocketService(companyUuid: 'uuid-001');
      final serviceB = WebSocketService(companyUuid: 'uuid-002');

      expect(serviceA.destination, isNot(equals(serviceB.destination)));
      expect(serviceA.topic, isNot(equals(serviceB.topic)));
    });
  });
}
