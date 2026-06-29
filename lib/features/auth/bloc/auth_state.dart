import 'package:equatable/equatable.dart';

import '../models/token_response.dart';
import '../models/user_profile.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final TokenResponse token;
  final UserProfile? profile;

  const AuthAuthenticated(this.token, {this.profile});

  @override
  List<Object?> get props => [token, profile];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
