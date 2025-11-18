// lib/features/auth/bloc/auth_state.dart

import 'package:equatable/equatable.dart';
import 'package:subasta/core/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel user;

  // 1. Hacemos el constructor principal 'const'
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user = const UserModel(id: ''),
  });

  // 2. Creamos los constructores nombrados 'const' que el BLoC necesita
  const AuthState.unknown() : this();

  const AuthState.authenticated(UserModel user)
      : this(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated()
      : this(status: AuthStatus.unauthenticated);

  @override
  List<Object> get props => [status, user];
}