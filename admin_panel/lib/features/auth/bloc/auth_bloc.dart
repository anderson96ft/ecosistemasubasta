// lib/features/auth/bloc/auth_bloc.dart
import 'dart:async';
import 'package:admin_panel/core/models/user_model.dart';
import 'package:admin_panel/core/repositories/auth_repository.dart'; // Ruta unificada
import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<UserModel>? _userSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthUserChanged>(_onAuthUserChanged);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);

    _userSubscription = _authRepository.user.listen((user) => add(AuthUserChanged(user)));
  }

  // --- LÓGICA CLAVE ---
  Future<void> _onAuthUserChanged(AuthUserChanged event, Emitter<AuthState> emit) async {
    print('[AuthBloc] AuthUserChanged recibido. User ID: ${event.user.id}');
    if (event.user.isEmpty) {
      // Si no hay usuario, es no autenticado y no es admin.
      print('[AuthBloc] Usuario vacío. Emitiendo estado unauthenticated.');
      return emit(state.copyWith(status: AuthStatus.unauthenticated, isAdmin: false, user: UserModel.empty));
    }
    
    // Si hay un usuario, comprobamos si es administrador.
    print('[AuthBloc] Comprobando si el usuario ${event.user.id} es admin...');
    final isAdmin = await _authRepository.isAdmin(userId: event.user.id);
    print('[AuthBloc] isAdmin para ${event.user.id} devolvió: $isAdmin');
    
    if (isAdmin) {
      // Si es admin, estado autenticado y isAdmin = true.
      print('[AuthBloc] El usuario es admin. Emitiendo estado authenticated.');
      emit(state.copyWith(status: AuthStatus.authenticated, user: event.user, isAdmin: true));
    } else {
      // Si no es admin, cerramos su sesión por seguridad y lo marcamos como no autenticado.
      print('[AuthBloc] El usuario NO es admin. Forzando logout y emitiendo estado unauthenticated.');
      await _authRepository.logOut();
      emit(state.copyWith(status: AuthStatus.unauthenticated, isAdmin: false, user: UserModel.empty));
    }
  }

  void _onAuthLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) {
    _authRepository.logOut();
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}