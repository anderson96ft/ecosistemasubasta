// lib/features/auth/bloc/auth_bloc.dart

import 'dart:async';
import 'package:subasta/core/models/user_model.dart';
import 'package:subasta/core/navigation/navigator_key.dart';
import 'package:subasta/core/repositories/auth_repository.dart';
import 'package:subasta/core/repositories/device_repository.dart';
import 'package:subasta/features/product_detail/presentation/screens/product_detail_screen.dart';
import 'package:bloc/bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart'; // Necesario para ScaffoldMessenger

// Asegúrate de que tu archivo de eventos esté en la misma carpeta o importa la ruta correcta
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final DeviceRepository _deviceRepository;
  final FirebaseMessaging _messaging;
  StreamSubscription<UserModel>? _userSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required DeviceRepository deviceRepository,
    required FirebaseMessaging messaging,
  })  : _authRepository = authRepository,
        _deviceRepository = deviceRepository,
        _messaging = messaging,
        super(const AuthState.unknown()) {
    
    _userSubscription = _authRepository.user.listen(
      (user) => add(AuthUserChanged(user)),
    );

    on<AuthUserChanged>(_onAuthUserChanged);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    
    // --- 1. REGISTRA EL NUEVO MANEJADOR ---
    on<RegisterFCMToken>(_onRegisterFCMToken);
  }

  Future<void> _onAuthUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user.isNotEmpty) {
      final firebaseUser = _authRepository.getCurrentFirebaseUser();
      if (firebaseUser == null) {
        // Esto no debería pasar si event.user.isNotEmpty, pero es una buena guarda
        return emit(const AuthState.unauthenticated());
      }

      // --- LÓGICA DE VERIFICACIÓN DE EMAIL (SI LA IMPLEMENTAS) ---
      // if (!firebaseUser.emailVerified) {
      //   try {
      //     await firebaseUser.sendEmailVerification();
      //   } catch (e) { /*...*/ }
      //   return emit(AuthState.pendingVerification(event.user));
      // }
      // --- FIN DE LÓGICA DE VERIFICACIÓN ---

      final userProfileSnapshot = await _authRepository.getUserProfile(event.user.id);

      // Si el perfil NO existe (USUARIO NUEVO)
      if (userProfileSnapshot == null) {
        print('Perfil no encontrado en Firestore para ${event.user.id}. Creando...');
        await _authRepository.createUserProfile(
          uid: event.user.id,
          email: event.user.email,
          phone: event.user.phone,
        );
        print('Perfil creado para ${event.user.id}.');

      } else {
        // El perfil SÍ existe (USUARIO ANTIGUO)
        final data = userProfileSnapshot.data() as Map<String, dynamic>?;
        if (data != null && data['status'] == 'banned') {
          print('Usuario ${event.user.id} está baneado. Cerrando sesión.');
          await _authRepository.logOut();
          return; // El stream de 'user' se actualizará y emitirá 'unauthenticated'
        }
         print('Usuario ${event.user.id} no está baneado.');
      }

      // --- REGISTRO AUTOMÁTICO DE TOKEN ---
      add(const RegisterFCMToken());

      // Emitimos el estado de 'autenticado'.
      emit(AuthState.authenticated(event.user));

    } else {
      // Usuario no autenticado
      emit(const AuthState.unauthenticated());
    }
  }

  void _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) {
    _authRepository.logOut();
  }

  // --- 3. NUEVO MÉTODO COMPLETO PARA GUARDADO MANUAL ---
  Future<void> _onRegisterFCMToken(
    RegisterFCMToken event,
    Emitter<AuthState> emit,
  ) async {
    // Solo se ejecuta si el usuario está autenticado
    if (state.status == AuthStatus.authenticated) {
      print('AuthBloc: [Prueba Manual] Intentando registrar token FCM...');
      try {
        await _deviceRepository.saveDeviceToken(userId: state.user.id);
        
        // ¡Si llegamos aquí, tu teoría es correcta!
        print('AuthBloc: [Prueba Manual] ¡Registro de token EXITOSO!');
        
        // Muestra un SnackBar de éxito
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
           ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
             const SnackBar(
               content: Text('Sincronización de notificaciones exitosa.'),
               backgroundColor: Colors.green,
             ),
           );
        }

      } catch (e) {
        // Si falla aquí, es 100% un problema de red/DNS en el dispositivo
        print('AuthBloc: [Prueba Manual] ¡Registro de token FALLÓ!: $e');
        
        // Muestra un SnackBar de error
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
           ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
             SnackBar(
               content: Text('Error al sincronizar notificaciones: $e'),
               backgroundColor: Colors.red,
             ),
           );
        }
      }
    } else {
      print('AuthBloc: [Prueba Manual] Usuario no autenticado. No se puede registrar token.');
    }
  }
  // --- FIN DE LA ADICIÓN ---

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}