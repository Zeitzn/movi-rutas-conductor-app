import '../../../core/errors/failures.dart';
import '../models/token_response.dart';

abstract class IAuthRepository {
  Future<void> saveToken(TokenResponse token);
  TokenResponse? getToken();
  Future<void> clearToken();
}

class InMemoryAuthRepository implements IAuthRepository {
  TokenResponse? _token;

  @override
  Future<void> saveToken(TokenResponse token) async {
    try {
      _token = token;
    } catch (e) {
      throw DatabaseFailure('Failed to save token: $e');
    }
  }

  @override
  TokenResponse? getToken() {
    return _token;
  }

  @override
  Future<void> clearToken() async {
    try {
      _token = null;
    } catch (e) {
      throw DatabaseFailure('Failed to clear token: $e');
    }
  }
}
