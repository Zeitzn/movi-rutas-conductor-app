import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/token_response.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepository;
  final AuthService _authService;
  Timer? _refreshTimer;

  AuthBloc({
    required IAuthRepository authRepository,
    required AuthService authService,
  }) : _authRepository = authRepository,
       _authService = authService,
       super(const AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<RefreshTokenRequested>(_onRefreshTokenRequested);
  }

  @override
  void onTransition(Transition<AuthEvent, AuthState> transition) {
    super.onTransition(transition);

    if (transition.nextState is AuthAuthenticated) {
      _startRefreshTimer(
        (transition.nextState as AuthAuthenticated).token,
      );
    } else if (transition.nextState is AuthUnauthenticated) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  void _startRefreshTimer(TokenResponse token) {
    _refreshTimer?.cancel();

    final refreshIn = (token.accessTokenRemainingSeconds * 0.8)
        .round()
        .clamp(1, 300);

    _refreshTimer = Timer(Duration(seconds: refreshIn), () {
      add(const RefreshTokenRequested());
    });
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final token = await _authService.login(
        username: event.username,
        password: event.password,
      );

      final tokenWithUser = token.copyWith(username: event.username);
      await _authRepository.saveToken(tokenWithUser);
      emit(AuthAuthenticated(tokenWithUser));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(message));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final token = await _authRepository.getToken();
      if (token == null || !token.canRefresh) {
        if (token != null) await _authRepository.clearToken();
        emit(const AuthUnauthenticated());
        return;
      }
      emit(AuthAuthenticated(token));
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onRefreshTokenRequested(
    RefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final currentToken = await _authRepository.getToken();
      if (currentToken == null || !currentToken.canRefresh) {
        await _authRepository.clearToken();
        emit(const AuthUnauthenticated());
        return;
      }

      final newToken = await _authService.refreshToken(
        currentToken.refreshToken,
      );

      // Preservar el username del token anterior — el endpoint de refresh
      // no lo incluye en la respuesta, y si lo pisamos se pierde.
      final updatedToken = newToken.copyWith(username: currentToken.username);
      await _authRepository.saveToken(updatedToken);
      emit(AuthAuthenticated(updatedToken));
    } catch (_) {
      await _authRepository.clearToken();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _authRepository.clearToken();
    emit(const AuthUnauthenticated());
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    return super.close();
  }
}
