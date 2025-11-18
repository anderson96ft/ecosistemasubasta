// lib/features/auth/bloc/login/login_bloc.dart
import 'dart:async';
import 'package:admin_panel/core/repositories/auth_repository.dart'; // Asegúrate que la ruta es correcta
import 'package:admin_panel/features/auth/bloc/auth_bloc.dart';
import 'package:bloc/bloc.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;
  final AuthBloc _authBloc;
  late StreamSubscription _authSubscription;

  LoginBloc({
    required AuthRepository authRepository,
    required AuthBloc authBloc,
  })
      : _authRepository = authRepository,
        _authBloc = authBloc,
        super(const LoginState()) { // <-- El punto y coma estaba mal aquí
    // Escuchamos al AuthBloc. Si el estado de autenticación cambia,
    // reseteamos el estado del LoginBloc para quitar el spinner.
    _authSubscription = _authBloc.stream.listen((authState) {
      print('[LoginBloc] AuthBloc emitió un nuevo estado: ${authState.status}');
      if (state.status == LoginStatus.loading) {
        print('[LoginBloc] El estado actual es loading. Añadiendo LoginStatusReset.');
        add(const LoginStatusReset());
      }
    });

    on<LoginEmailChanged>((event, emit) => emit(state.copyWith(email: event.email)));
    on<LoginPasswordChanged>((event, emit) => emit(state.copyWith(password: event.password)));
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginStatusReset>((event, emit) => emit(state.copyWith(status: LoginStatus.initial)));
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    if (!state.isValid) return;
    print('[LoginBloc] LoginSubmitted recibido. Emitiendo estado de loading.');
    emit(state.copyWith(status: LoginStatus.loading));
    try {
      print('[LoginBloc] Llamando a logInWithEmailAndPassword...');
      await _authRepository.logInWithEmailAndPassword(
        email: state.email,
        password: state.password,
      );
      // OJO: No necesitamos emitir 'success' aquí. El AuthBloc
      // detectará el cambio y hará la verificación de rol. Si tiene éxito,
      // nos llevará al dashboard. Si no, nos deslogueará.
      print('[LoginBloc] logInWithEmailAndPassword completado. Esperando a AuthBloc.');
    } catch (e) {
      print('[LoginBloc] ERROR durante el login: $e');
      emit(state.copyWith(status: LoginStatus.failure, errorMessage: 'Credenciales inválidas.'));
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}