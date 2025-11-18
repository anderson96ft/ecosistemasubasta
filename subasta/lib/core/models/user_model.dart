// lib/core/models/user_model.dart

import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String? email;
  final String? phone; // <-- 1. NUEVO CAMPO AÑADIDO

  // 2. CONSTRUCTOR ACTUALIZADO
  const UserModel({
    required this.id,
    this.email,
    this.phone, // <-- Parámetro añadido
  });

  /// Un usuario vacío para representar el estado de 'no autenticado'.
  static const empty = UserModel(id: '');

  /// Comprueba si el usuario actual es el usuario vacío.
  bool get isEmpty => this == UserModel.empty;

  /// Comprueba si el usuario actual no es el usuario vacío.
  bool get isNotEmpty => this != UserModel.empty;

  // 3. PROPS ACTUALIZADOS
  @override
  List<Object?> get props => [id, email, phone];
}