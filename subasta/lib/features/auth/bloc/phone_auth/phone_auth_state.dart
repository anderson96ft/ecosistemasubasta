// lib/features/auth/bloc/phone_auth/phone_auth_state.dart
part of 'phone_auth_bloc.dart';

// Enum para representar los diferentes estados del flujo de autenticación por teléfono.
enum PhoneAuthStatus {
  initial, // Estado inicial, esperando que el usuario introduzca un número.
  loading, // Mostrando un spinner (ej. mientras se envía el SMS o se verifica el código).
  codeSent, // El SMS fue enviado con éxito, la UI debe navegar a la pantalla de OTP.
  verificationSuccess, // El código SMS es correcto y el usuario ha iniciado sesión.
  verificationFailure, // Ha ocurrido un error (ej. número inválido, código incorrecto, etc.).
}

class PhoneAuthState extends Equatable {
  final PhoneAuthStatus status;
  final String
      verificationId; // Se guarda aquí después de que Firebase envía el código.
  final String errorMessage;

  // --- PROPIEDADES AÑADIDAS PARA VALIDACIÓN EN TIEMPO REAL ---
  final String
      phoneNumber; // Almacena el número que el usuario está escribiendo.
  final bool isPhoneNumberValid; // Indica si el número tiene un formato válido.

  const PhoneAuthState({
    this.status = PhoneAuthStatus.initial,
    this.verificationId = '',
    this.errorMessage = '',
    this.phoneNumber = '',
    this.isPhoneNumberValid = false,
  });

  PhoneAuthState copyWith({
    PhoneAuthStatus? status,
    String? verificationId,
    String? errorMessage,
    String? phoneNumber,
    bool? isPhoneNumberValid,
  }) {
    return PhoneAuthState(
      status: status ?? this.status,
      verificationId: verificationId ?? this.verificationId,
      errorMessage: errorMessage ?? this.errorMessage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPhoneNumberValid: isPhoneNumberValid ?? this.isPhoneNumberValid,
    );
  }

  @override
  List<Object> get props => [
        status,
        verificationId,
        errorMessage,
        phoneNumber,
        isPhoneNumberValid,
      ];
}