import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/env_config.dart';
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

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': username,
          'password': password.toUpperCase(),
          'grant_type': AppConstants.authGrantType,
          'client_id': AppConstants.authClientId,
          'client_secret': EnvConfig.instance.authClientSecret,
        },
      );

      return _handleResponse(response);
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Error de conexión: $e');
    }
  }

  Future<TokenResponse> refreshToken(String refreshToken) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.authHost}${AppConstants.authTokenEndpoint}',
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': AppConstants.authRefreshGrantType,
          'refresh_token': refreshToken,
          'client_id': AppConstants.authClientId,
          'client_secret': EnvConfig.instance.authClientSecret,
        },
      );

      return _handleResponse(response);
    } on Failure {
      rethrow;
    } catch (e) {
      throw NetworkFailure('Error de conexión: $e');
    }
  }

  TokenResponse _handleResponse(http.Response response) {
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
  }
}
