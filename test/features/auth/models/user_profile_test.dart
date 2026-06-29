import 'package:flutter_test/flutter_test.dart';
import 'package:movi_rutas_example/features/auth/models/user_profile.dart';

void main() {
  group('UserProfile roundtrip', () {
    test('toJson/fromJson with all fields populated', () {
      final original = const UserProfile(
        uuid: '123e4567-e89b-12d3-a456-426614174000',
        username: 'DRIVER01',
        firstName: 'Carlos',
        lastName: 'García',
        companyUuid: 'comp-001',
        companyCode: 'MOVI',
      );

      final json = original.toJson();
      final reconstructed = UserProfile.fromJson(json);

      expect(reconstructed, equals(original));
    });

    test('fromJson parses data envelope from realistic API response', () {
      final apiResponse = {
        'data': {
          'uuid': '123e4567-e89b-12d3-a456-426614174000',
          'username': 'DRIVER01',
          'firstName': 'Carlos',
          'lastName': 'García',
          'companyUuid': 'comp-001',
          'companyCode': 'MOVI',
        },
      };

      final data = apiResponse['data'] as Map<String, dynamic>;
      final profile = UserProfile.fromJson(data);

      expect(profile.uuid, '123e4567-e89b-12d3-a456-426614174000');
      expect(profile.username, 'DRIVER01');
      expect(profile.firstName, 'Carlos');
      expect(profile.lastName, 'García');
      expect(profile.companyUuid, 'comp-001');
      expect(profile.companyCode, 'MOVI');
    });
  });
}
