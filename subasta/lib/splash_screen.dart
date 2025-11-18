// lib/splash_screen.dart
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:subasta/features/auth/bloc/auth_state.dart';
import 'package:subasta/features/nav/presentation/screens/nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // BlocListener escucha los cambios de estado para navegar
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Cuando el estado de autenticación ya no sea 'unknown' (es decir, ya se ha determinado
        // si el usuario está logueado o no), navegamos a la pantalla principal.
        if (state.status != AuthStatus.unknown) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const NavScreen()),
          );
        }
      },
      // Mientras esperamos, mostramos una pantalla de carga simple.
      child: const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}