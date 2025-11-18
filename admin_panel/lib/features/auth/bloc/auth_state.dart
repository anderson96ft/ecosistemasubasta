part of 'auth_bloc.dart';

enum AuthStatus { authenticated, unauthenticated }

class AuthState extends Equatable {
  final UserModel user;
  final AuthStatus status;
  final bool isAdmin;

  const AuthState({
    this.user = const UserModel(id: ''),
    this.status = AuthStatus.unauthenticated,
    this.isAdmin = false,
  });

  AuthState copyWith({
    UserModel? user,
    AuthStatus? status,
    bool? isAdmin,
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  @override
  List<Object?> get props => [user, status, isAdmin];
}