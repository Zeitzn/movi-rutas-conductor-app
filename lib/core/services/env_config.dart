import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/failures.dart';

/// Centralized typed configuration service.
///
/// Loads configuration from:
/// - `.env` file (via flutter_dotenv) for secrets
/// - `SharedPreferences` for per-device runtime config
///
/// ⚠️ PKCE CAVEAT (mobile client_secret)
/// The `authClientSecret` is loaded from `.env` and bundled into the APK.
/// On mobile, client_secret is NOT a secret — it can be extracted from the
/// binary. This is a KNOWN LIMITATION of the OAuth2 authorization_code flow
/// with public clients. The REAL fix is PKCE (Proof Key for Code Exchange),
/// which eliminates the need for client_secret entirely.
///
/// PKCE migration is tracked separately and requires Keycloak realm changes.
/// Until then, the secret provides a minimal barrier but MUST NOT be relied
/// upon as a security boundary.
class EnvConfig {
  EnvConfig._();

  static final EnvConfig _instance = EnvConfig._();

  /// Singleton instance.
  static EnvConfig get instance => _instance;

  static bool _initialized = false;
  SharedPreferences? _prefs;

  /// Initialize from all sources.
  ///
  /// Call once at app startup, after `WidgetsFlutterBinding.ensureInitialized()`.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await dotenv.load(fileName: 'assets/.env');

    _instance._prefs = await SharedPreferences.getInstance();
  }

  /// Keycloak client secret from `.env`.
  ///
  /// ⚠️ See PKCE caveat above — this is NOT a real secret on mobile.
  String get authClientSecret {
    return dotenv.env['AUTH_CLIENT_SECRET'] ?? '';
  }

  /// Driver's vehicle number plate from SharedPreferences.
  ///
  /// Returns empty string if not configured. Set via:
  /// ```dart
  /// final prefs = await SharedPreferences.getInstance();
  /// await prefs.setString('numberPlate', 'ABC-123');
  /// ```
  ///
  /// A Settings UI for numberPlate input is tracked separately.
  String get numberPlate {
    return _prefs?.getString('numberPlate') ?? '';
  }

  /// Profiles API base URL from `.env`.
  ///
  /// Used to fetch driver profile after login.
  String get profilesApiBaseUrl {
    final url = dotenv.env['PROFILES_API_BASE_URL'] ?? 'http://localhost:8080';
    if (url.isEmpty) {
      throw const ServerFailure('PROFILES_API_BASE_URL is not set in .env');
    }
    return url;
  }
}
