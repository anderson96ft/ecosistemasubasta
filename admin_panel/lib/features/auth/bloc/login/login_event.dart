// lib/features/auth/bloc/login/login_event.dart
import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();
  @override
  List<Object> get props => [];
}

class LoginEmailChanged extends LoginEvent {
  final String email;
  const LoginEmailChanged(this.email);
}

class LoginPasswordChanged extends LoginEvent {
  final String password;
  const LoginPasswordChanged(this.password);
}

class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}

// Evento interno para resetear el estado del BLoC.
class LoginStatusReset extends LoginEvent {
  const LoginStatusReset();
}