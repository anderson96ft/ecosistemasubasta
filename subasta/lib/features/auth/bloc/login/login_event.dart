// lib/features/auth/bloc/login/login_event.dart
part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();
  @override
  List<Object> get props => [];
}

/// Único evento: Se dispara cuando el usuario presiona el botón de Google.
class LoginWithGoogleSubmitted extends LoginEvent {
  const LoginWithGoogleSubmitted();
}

// Todos los demás eventos (EmailChanged, PasswordChanged, LoginSubmitted, SignUp...)
// han sido eliminados.