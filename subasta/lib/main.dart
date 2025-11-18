// lib/main.dart

import 'dart:async';
import 'package:subasta/core/services/notification_service.dart'; // <-- 1. IMPORTA EL SERVICIO
import 'dart:io'; // Para SocketException
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:subasta/core/navigation/navigator_key.dart';
import 'package:subasta/core/repositories/auth_repository.dart';
import 'package:subasta/core/repositories/chat_repository.dart';
import 'package:subasta/core/repositories/device_repository.dart';
import 'package:subasta/core/repositories/product_repository.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:subasta/features/auth/bloc/auth_state.dart';
import 'package:subasta/features/nav/presentation/screens/nav_screen.dart';
import 'package:subasta/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart'; // <-- IMPORTA GOOGLE SIGN IN
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa para FirebaseFirestore
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Importa para FirebaseAuth

Future<void> testHttpConnection() async {
  // (Este es tu código de prueba de conexión, lo mantenemos)
  final url = Uri.parse(
    'https://firestore.googleapis.com',
  );
  print('Intentando conectar a: $url');
  try {
    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 10));
    print('Conexión HTTP exitosa! Código de estado: ${response.statusCode}');
  } on SocketException catch (e) {
    print('Error de Socket (DNS o Red): ${e.message}');
    if (e.osError != null) {
      print('Detalle del OS Error: ${e.osError}');
    }
  } on TimeoutException catch (_) {
    print('Error: La conexión tardó demasiado (Timeout).');
  } catch (e) {
    print('Error HTTP inesperado: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await testHttpConnection(); // Llama a la prueba de red

  // Comprueba si Firebase ya está inicializado para evitar errores de Hot Restart
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    Firebase.app(); // Usa la app [DEFAULT] existente
  }

  // --- 2. INICIALIZA EL SERVICIO DE NOTIFICACIONES ---
  // Esto activará todos los listeners (onMessage, onMessageOpenedApp, etc.)
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiRepositoryProvider inyecta todas las dependencias
    return MultiRepositoryProvider(
      providers: [
        // --- 1. Provee GoogleSignIn ---
        RepositoryProvider(
          create: (_) => GoogleSignIn(),
        ),
        // --- 2. Provee AuthRepository (que ahora depende de GoogleSignIn) ---
        RepositoryProvider(
          create: (context) => AuthRepository(
            firebaseAuth: firebase_auth.FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
            googleSignIn: context.read<GoogleSignIn>(), // Inyecta GoogleSignIn
          ),
        ),
        // Los otros repositorios permanecen igual
        RepositoryProvider(create: (_) => ProductRepository()),
        RepositoryProvider(create: (_) => DeviceRepository()),
        RepositoryProvider(create: (_) => ChatRepository()),
      ],
      // BlocProvider global para AuthBloc
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
          deviceRepository: context.read<DeviceRepository>(),
          messaging: FirebaseMessaging.instance,
        ),
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auction App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorKey: navigatorKey, // Tu clave global de navegación
      debugShowCheckedModeBanner: false,
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Si el estado es 'unknown', muestra una pantalla de carga
          if (state.status == AuthStatus.unknown) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // --- LÓGICA SIMPLIFICADA ---
          // Ya no hay estado 'pendingVerification'.
          // NavScreen manejará si el usuario está logueado o no.
          return const NavScreen();
        },
      ),
    );
  }
}