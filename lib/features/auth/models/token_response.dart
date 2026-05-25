import 'package:equatable/equatable.dart';

class TokenResponse extends Equatable {
  final String accessToken;
  final int expiresIn;
  final int refreshExpiresIn;
  final String refreshToken;
  final String tokenType;
  final int notBeforePolicy;
  final String sessionState;
  final String scope;
  final DateTime issuedAt;
  final String? username;

  TokenResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.refreshExpiresIn,
    required this.refreshToken,
    required this.tokenType,
    this.notBeforePolicy = 0,
    this.sessionState = '',
    this.scope = '',
    this.username,
    DateTime? issuedAt,
  }) : issuedAt = issuedAt ?? DateTime.now();

  /// `true` si el access_token ya expiró.
  bool get isAccessTokenExpired =>
      DateTime.now().isAfter(issuedAt.add(Duration(seconds: expiresIn)));

  /// `true` si todavía se puede hacer refresh (refresh_token vigente).
  bool get canRefresh =>
      !DateTime.now().isAfter(
        issuedAt.add(Duration(seconds: refreshExpiresIn)),
      );

  /// Segundos hasta que expire el access_token.
  int get accessTokenRemainingSeconds =>
      issuedAt.add(Duration(seconds: expiresIn)).difference(DateTime.now()).inSeconds;

  TokenResponse copyWith({
    String? accessToken,
    int? expiresIn,
    int? refreshExpiresIn,
    String? refreshToken,
    String? tokenType,
    int? notBeforePolicy,
    String? sessionState,
    String? scope,
    String? username,
    DateTime? issuedAt,
  }) {
    return TokenResponse(
      accessToken: accessToken ?? this.accessToken,
      expiresIn: expiresIn ?? this.expiresIn,
      refreshExpiresIn: refreshExpiresIn ?? this.refreshExpiresIn,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      notBeforePolicy: notBeforePolicy ?? this.notBeforePolicy,
      sessionState: sessionState ?? this.sessionState,
      scope: scope ?? this.scope,
      username: username ?? this.username,
      issuedAt: issuedAt ?? this.issuedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'expires_in': expiresIn,
      'refresh_expires_in': refreshExpiresIn,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'not-before-policy': notBeforePolicy,
      'session_state': sessionState,
      'scope': scope,
      'username': username,
      'issued_at': issuedAt.toIso8601String(),
    };
  }

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      refreshExpiresIn: (json['refresh_expires_in'] as num).toInt(),
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      notBeforePolicy: (json['not-before-policy'] as num?)?.toInt() ?? 0,
      sessionState: json['session_state'] as String? ?? '',
      scope: json['scope'] as String? ?? '',
      username: json['username'] as String?,
      issuedAt: json['issued_at'] != null
          ? DateTime.parse(json['issued_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    accessToken,
    expiresIn,
    refreshExpiresIn,
    refreshToken,
    tokenType,
    notBeforePolicy,
    sessionState,
    scope,
    username,
    issuedAt,
  ];

  @override
  String toString() {
    return 'TokenResponse(accessToken: $accessToken, tokenType: $tokenType, '
        'expiresIn: $expiresIn, refreshExpiresIn: $refreshExpiresIn, '
        'canRefresh: $canRefresh)';
  }
}
