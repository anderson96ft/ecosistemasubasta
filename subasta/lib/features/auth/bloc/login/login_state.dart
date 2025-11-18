// lib/features/auth/bloc/login/login_state.dart
part of 'login_bloc.dart';

class LoginState extends Equatable {
  const LoginState({
    this.status = FormzSubmissionStatus.initial,
    this.errorMessage,
  });

  final FormzSubmissionStatus status;
  final String? errorMessage;

  LoginState copyWith({
    FormzSubmissionStatus? status,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}

// Las clases 'EmailInput' y 'PasswordInput' de Formz han sido eliminadas.