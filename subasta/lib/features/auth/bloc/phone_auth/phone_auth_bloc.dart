// lib/features/auth/bloc/phone_auth/phone_auth_bloc.dart

import 'dart:async';
import 'package:subasta/core/repositories/auth_repository.dart'; // Asegúrate que la ruta sea correcta
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart'; // <-- IMPORTANTE: Añade Equatable aquí
import 'package:firebase_auth/firebase_auth.dart'; // <-- IMPORTANTE: Añade Firebase Auth aquí

// Declara los 'part' (partes) que componen este BLoC
part 'phone_auth_event.dart';
part 'phone_auth_state.dart';

class PhoneAuthBloc extends Bloc<PhoneAuthEvent, PhoneAuthState> {
  final AuthRepository _authRepository;

  PhoneAuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const PhoneAuthState()) {
    // Registra todos los manejadores de eventos
    on<PhoneAuthReset>((event, emit) => emit(const PhoneAuthState()));
    on<PhoneNumberChanged>(_onPhoneNumberChanged);
    on<PhoneNumberSubmitted>(_onPhoneNumberSubmitted);
    on<SmsCodeSubmitted>(_onSmsCodeSubmitted);
    on<PhoneAuthVerificationCompleted>(_onVerificationCompleted);
    on<PhoneAuthVerificationFailed>(_onVerificationFailed);
    on<PhoneAuthCodeSent>(_onCodeSent);
  }

  void _onPhoneNumberChanged(
    PhoneNumberChanged event,
    Emitter<PhoneAuthState> emit,
  ) {
    // Valida el número de teléfono (simple)
    final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
    final isValid = phoneRegex.hasMatch(event.phoneNumber);
    emit(
      state.copyWith(
        phoneNumber: event.phoneNumber,
        isPhoneNumberValid: isValid,
        status: PhoneAuthStatus.initial, // Resetea el estado
        errorMessage: '',
      ),
    );
  }

  Future<void> _onPhoneNumberSubmitted(
    PhoneNumberSubmitted event,
    Emitter<PhoneAuthState> emit,
  ) async {
    // Solo envía si el número es válido
    if (!state.isPhoneNumberValid) return;

    emit(
      state.copyWith(
        status: PhoneAuthStatus.loading,
        phoneNumber: event.phoneNumber, // Guarda el número que se está verificando
        errorMessage: '',
      ),
    );
    try {
      print('PhoneAuthBloc: Llamando a verifyPhoneNumber con ${event.phoneNumber}');
      await _authRepository.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        // Estos son los callbacks que Firebase llamará
        verificationCompleted: (credential) =>
            add(PhoneAuthVerificationCompleted(credential)),
        verificationFailed: (exception) =>
            add(PhoneAuthVerificationFailed(exception)),
        codeSent: (verificationId, resendToken) =>
            add(PhoneAuthCodeSent(verificationId, resendToken)),
      );
    } catch (e) {
      print('Error al llamar a verifyPhoneNumber: $e');
      emit(
        state.copyWith(
          status: PhoneAuthStatus.verificationFailure,
          errorMessage: 'Ocurrió un error al iniciar la verificación.',
        ),
      );
    }
  }

  Future<void> _onSmsCodeSubmitted(
    SmsCodeSubmitted event,
    Emitter<PhoneAuthState> emit,
  ) async {
    // Asegura que tengamos un ID de verificación
    if (state.verificationId.isEmpty) {
       print('Error: Se intentó enviar SMS Code pero verificationId estaba vacío.');
       emit(
        state.copyWith(
          status: PhoneAuthStatus.verificationFailure,
          errorMessage: 'Error interno. Falta el ID de verificación.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PhoneAuthStatus.loading, errorMessage: ''));

    // --- LOGS DE DEPURACIÓN ---
    print('Intentando verificar SMS...');
    print('Verification ID desde el estado: ${state.verificationId}');
    print('SMS Code desde el evento: ${event.smsCode}');
    // --- FIN DEL LOG ---

    try {
      await _authRepository.signInWithSmsCode(
        verificationId: state.verificationId,
        smsCode: event.smsCode,
      );
      print('Verificación exitosa en el repositorio!');
      emit(state.copyWith(status: PhoneAuthStatus.verificationSuccess));
    } on FirebaseAuthException catch (e) { // Captura errores específicos
       print('Error específico de FirebaseAuth en signInWithSmsCode: ${e.code} - ${e.message}');
       emit(
        state.copyWith(
          status: PhoneAuthStatus.verificationFailure,
          // Mapea el error más común
          errorMessage: e.code == 'invalid-verification-code' 
              ? 'El código introducido no es válido.'
              : 'Error de verificación: ${e.message}',
        ),
      );
    }
     catch (e) { // Captura cualquier otro error
      print('Error inesperado en signInWithSmsCode: $e');
      emit(
        state.copyWith(
          status: PhoneAuthStatus.verificationFailure,
          errorMessage: 'Ocurrió un error inesperado al verificar el código.',
        ),
      );
    }
  }

  // Manejador para el callback 'verificationCompleted' (autocompletado en Android)
  Future<void> _onVerificationCompleted(
    PhoneAuthVerificationCompleted event,
    Emitter<PhoneAuthState> emit,
  ) async {
    print('Verificación completada automáticamente (autocompletado).');
    emit(state.copyWith(status: PhoneAuthStatus.loading, errorMessage: ''));
    try {
      // Inicia sesión directamente con la credencial recibida
      await _authRepository.signInWithCredential(event.credential);
      print('Inicio de sesión exitoso con credencial autocompletada.');
      emit(state.copyWith(status: PhoneAuthStatus.verificationSuccess));
    } catch (e) {
      print('Error al iniciar sesión con credencial autocompletada: $e');
      emit(
        state.copyWith(
          status: PhoneAuthStatus.verificationFailure,
          errorMessage: 'La autoverificación falló. Ingresa el código manualmente.',
        ),
      );
    }
  }

  // Manejador para el callback 'verificationFailed'
  void _onVerificationFailed(
    PhoneAuthVerificationFailed event,
    Emitter<PhoneAuthState> emit,
  ) {
    print('Error en verificationFailed: ${event.exception.code} - ${event.exception.message}');
    String message;
    switch (event.exception.code) {
      case 'invalid-phone-number':
        message = 'El número de teléfono no es válido.';
        break;
      case 'too-many-requests':
        message = 'Demasiados intentos. Inténtalo más tarde.';
        break;
      case 'missing-activity': // El error que mencionaste
         message = 'Se requiere verificación adicional. Por favor, asegúrate de que la app esté en primer plano.';
         break;
      // Añade más casos según necesites
      default:
        message = 'No se pudo verificar el número. (${event.exception.code})';
    }
    emit(
      state.copyWith(
        status: PhoneAuthStatus.verificationFailure,
        errorMessage: message,
      ),
    );
  }

  // Manejador para el callback 'codeSent'
  void _onCodeSent(PhoneAuthCodeSent event, Emitter<PhoneAuthState> emit) {
    print('Recibido codeSent con Verification ID: ${event.verificationId}');
    emit(
      state.copyWith(
        status: PhoneAuthStatus.codeSent, // <-- Cambia a codeSent para navegar a OtpScreen
        verificationId: event.verificationId, // <-- Guarda el ID de verificación
        errorMessage: '',
      ),
    );
  }
}