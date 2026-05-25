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
       super(_initialState(authRepository)) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<RefreshTokenRequested>(_onRefreshTokenRequested);
  }

  static AuthState _initialState(IAuthRepository authRepository) {
    final token = authRepository.getToken();
    if (token == null) return const AuthUnauthenticated();
    if (!token.canRefresh) {
      authRepository.clearToken();
      return const AuthUnauthenticated();
    }
    return AuthAuthenticated(token);
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

    // Refrescar al 80% del tiempo de vida del access_token
    final refreshIn = (token.accessTokenRemainingSeconds * 0.8).round().clamp(1, 300);

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

      await _authRepository.saveToken(token);
      emit(AuthAuthenticated(token));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(message));
    }
  }

  Future<void> _onRefreshTokenRequested(
    RefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentToken = _authRepository.getToken();
    if (currentToken == null || !currentToken.canRefresh) {
      await _authRepository.clearToken();
      emit(const AuthUnauthenticated());
      return;
    }

    try {
      final newToken = await _authService.refreshToken(
        currentToken.refreshToken,
      );

      await _authRepository.saveToken(newToken);
      emit(AuthAuthenticated(newToken));
    } catch (e) {
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

  void _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) {
    final token = _authRepository.getToken();
    if (token == null || !token.canRefresh) {
      _authRepository.clearToken();
      emit(const AuthUnauthenticated());
      return;
    }
    emit(AuthAuthenticated(token));
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    return super.close();
  }
}
