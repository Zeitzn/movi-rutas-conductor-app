import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/failures.dart';
import '../models/token_response.dart';

abstract class IAuthRepository {
  Future<void> saveToken(TokenResponse token);
  Future<TokenResponse?> getToken();
  Future<void> clearToken();
}

class SharedPrefsAuthRepository implements IAuthRepository {
  static const _tokenKey = 'auth_token';

  TokenResponse? _cache;

  @override
  Future<void> saveToken(TokenResponse token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(token.toJson());
      await prefs.setString(_tokenKey, json);
      _cache = token;
    } catch (e) {
      throw DatabaseFailure('Failed to save token: $e');
    }
  }

  @override
  Future<TokenResponse?> getToken() async {
    if (_cache != null) return _cache;

    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_tokenKey);
      if (json == null) return null;

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      _cache = TokenResponse.fromJson(decoded);
      return _cache;
    } catch (e) {
      throw DatabaseFailure('Failed to read token: $e');
    }
  }

  @override
  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      _cache = null;
    } catch (e) {
      throw DatabaseFailure('Failed to clear token: $e');
    }
  }
}
