import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepository;
  final AuthService _authService;

  AuthBloc({
    required IAuthRepository authRepository,
    required AuthService authService,
  }) : _authRepository = authRepository,
       _authService = authService,
       super(_initialState(authRepository)) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  static AuthState _initialState(IAuthRepository authRepository) {
    final token = authRepository.getToken();
    if (token != null) return AuthAuthenticated(token);
    return const AuthUnauthenticated();
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

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.clearToken();
    emit(const AuthUnauthenticated());
  }

  void _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) {
    final token = _authRepository.getToken();
    if (token != null) {
      emit(AuthAuthenticated(token));
    } else {
      emit(const AuthUnauthenticated());
    }
  }
}
