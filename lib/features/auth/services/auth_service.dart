import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../models/token_response.dart';

class AuthService {
  Future<TokenResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.authHost}${AppConstants.authTokenEndpoint}',
      );
      print('AuthService: Sending login request to $uri');
      print('AuthService: Username: $username');
      print('AuthService: Password: $password');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': username,
          'password': password,
          'grant_type': AppConstants.authGrantType,
          'client_id': AppConstants.authClientId,
          'client_secret': AppConstants.authClientSecret,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return TokenResponse.fromJson(json);
      } else if (response.statusCode == 401) {
        throw const ServerFailure('Usuario o contraseña incorrectos');
      } else {
        throw ServerFailure(
          'Error del servidor: ${response.statusCode}',
        );
      }
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Error de conexión: $e');
    }
  }
}
