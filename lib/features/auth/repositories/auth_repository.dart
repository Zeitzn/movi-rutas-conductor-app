import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/failures.dart';
import '../models/token_response.dart';
import '../models/user_profile.dart';

abstract class IAuthRepository {
  Future<void> saveToken(TokenResponse token);
  Future<TokenResponse?> getToken();
  Future<void> clearToken();
  Future<void> saveProfile(UserProfile profile);
  Future<UserProfile?> getProfile();
  Future<void> clearProfile();
}

class SharedPrefsAuthRepository implements IAuthRepository {
  static const _tokenKey = 'auth_token';
  static const _profileKey = 'auth_profile';

  TokenResponse? _tokenCache;
  UserProfile? _profileCache;

  @override
  Future<void> saveToken(TokenResponse token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(token.toJson());
      await prefs.setString(_tokenKey, json);
      _tokenCache = token;
    } catch (e) {
      throw DatabaseFailure('Failed to save token: $e');
    }
  }

  @override
  Future<TokenResponse?> getToken() async {
    if (_tokenCache != null) return _tokenCache;

    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_tokenKey);
      if (json == null) return null;

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      _tokenCache = TokenResponse.fromJson(decoded);
      return _tokenCache;
    } catch (e) {
      throw DatabaseFailure('Failed to read token: $e');
    }
  }

  @override
  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_profileKey);
      _tokenCache = null;
      _profileCache = null;
    } catch (e) {
      throw DatabaseFailure('Failed to clear token: $e');
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(profile.toJson());
      await prefs.setString(_profileKey, json);
      _profileCache = profile;
    } catch (e) {
      throw DatabaseFailure('Failed to save profile: $e');
    }
  }

  @override
  Future<UserProfile?> getProfile() async {
    if (_profileCache != null) return _profileCache;

    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_profileKey);
      if (json == null) return null;

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      _profileCache = UserProfile.fromJson(decoded);
      return _profileCache;
    } catch (e) {
      throw DatabaseFailure('Failed to read profile: $e');
    }
  }

  @override
  Future<void> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      _profileCache = null;
    } catch (e) {
      throw DatabaseFailure('Failed to clear profile: $e');
    }
  }
}
