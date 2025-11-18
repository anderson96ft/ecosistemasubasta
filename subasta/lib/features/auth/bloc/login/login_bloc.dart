// lib/features/auth/bloc/login/login_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart'; // Aún lo usamos para FormzSubmissionStatus
import 'package:subasta/core/repositories/auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';


class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;

  LoginBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const LoginState()) {
    
    // Único manejador de evento
    on<LoginWithGoogleSubmitted>(_onLoginWithGoogleSubmitted);
  }

  Future<void> _onLoginWithGoogleSubmitted(
    LoginWithGoogleSubmitted event, Emitter<LoginState> emit
  ) async {
    // Pone la UI en estado de carga
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
    try {
      // Llama al repositorio para iniciar el flujo de Google
      await _authRepository.logInWithGoogle();
      // Si tiene éxito, emite 'success'. El AuthBloc global se encargará
      // de la navegación cuando detecte el cambio de estado de Firebase Auth.
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } catch (e) {
      // Si el usuario cancela o hay un error, emite 'failure'
      emit(state.copyWith(
        status: FormzSubmissionStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}