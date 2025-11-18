// lib/features/auth/bloc/phone_auth/phone_auth_event.dart

part of 'phone_auth_bloc.dart';

abstract class PhoneAuthEvent extends Equatable {
  const PhoneAuthEvent();
  @override
  List<Object?> get props => [];
}

/// Se dispara cuando el usuario cambia el texto en el campo del teléfono.
class PhoneNumberChanged extends PhoneAuthEvent {
  final String phoneNumber;
  const PhoneNumberChanged(this.phoneNumber);
   @override
  List<Object> get props => [phoneNumber];
}

/// Se dispara cuando el usuario presiona el botón "Enviar Código".
class PhoneNumberSubmitted extends PhoneAuthEvent {
  final String phoneNumber;
  const PhoneNumberSubmitted(this.phoneNumber);
   @override
  List<Object> get props => [phoneNumber];
}

/// Se dispara cuando el usuario presiona "Verificar" en la pantalla de OTP.
class SmsCodeSubmitted extends PhoneAuthEvent {
  final String smsCode;
  const SmsCodeSubmitted(this.smsCode);
   @override
  List<Object> get props => [smsCode];
}

/// Se dispara cuando el usuario quiere reiniciar el flujo (ej. al volver a la pantalla de input).
class PhoneAuthReset extends PhoneAuthEvent {}

// --- Eventos Internos (disparados por los callbacks de Firebase) ---

/// Evento interno para el callback 'verificationCompleted' (autocompletado)
class PhoneAuthVerificationCompleted extends PhoneAuthEvent {
  final PhoneAuthCredential credential;
  const PhoneAuthVerificationCompleted(this.credential);
}

/// Evento interno para el callback 'verificationFailed'
class PhoneAuthVerificationFailed extends PhoneAuthEvent {
  final FirebaseAuthException exception;
  const PhoneAuthVerificationFailed(this.exception);
}

/// Evento interno para el callback 'codeSent'
class PhoneAuthCodeSent extends PhoneAuthEvent {
  final String verificationId;
  final int? resendToken;
  const PhoneAuthCodeSent(this.verificationId, this.resendToken);
}