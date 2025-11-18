// lib/features/auth/bloc/auth_event.dart
import 'package:equatable/equatable.dart';
import 'package:subasta/core/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

// Este evento se dispara cuando el Stream del repositorio nos trae un nuevo usuario.
class AuthUserChanged extends AuthEvent {
  final UserModel user;
  const AuthUserChanged(this.user);
  @override
  List<Object> get props => [user];
}

// Este evento se dispara cuando el usuario presiona el botón "Logout".
class AuthLogoutRequested extends AuthEvent {}
// --- ¡AÑADE ESTE NUEVO EVENTO! ---
// Se dispara cuando el usuario presiona el botón manual
class RegisterFCMToken extends AuthEvent {
  const RegisterFCMToken();
}
// --- FIN DE LA ADICIÓN ---