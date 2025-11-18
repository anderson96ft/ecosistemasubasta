// lib/features/auth/presentation/screens/login_screen.dart
import 'package:subasta/core/repositories/auth_repository.dart';
import 'package:subasta/features/auth/bloc/login/login_bloc.dart';
// --- 1. IMPORTA LA PANTALLA DE TELÉFONO ---
import 'package:subasta/features/auth/presentation/screens/phone_input_screen.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
      ),
      body: BlocProvider(
        create: (context) => LoginBloc(
          authRepository: context.read<AuthRepository>(),
        ),
        child: const LoginForm(),
      ),
    );
  }
}

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        // Muestra SnackBar si falla CUALQUIER método de login
        if (state.status.isFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Error de Autenticación'),
                backgroundColor: Colors.red,
              ),
            );
        }
        // Cierra la pantalla si CUALQUIER método tiene éxito
        if (state.status.isSuccess) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                'Inicia sesión para continuar',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Usa tu cuenta de Google o número de teléfono para pujar, comprar y gestionar tu actividad.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Botón de Google o Indicador de Carga
              _GoogleLoginButton(), // Widget del botón de Google

              const SizedBox(height: 16),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("O"),
                ),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),

              // --- 2. NUEVO BOTÓN PARA INICIAR SESIÓN POR TELÉFONO ---
              OutlinedButton.icon(
                icon: const Icon(Icons.phone_android_outlined),
                label: const Text('Continuar con número de teléfono'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  // Navega a la pantalla de PhoneInputScreen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PhoneInputScreen(),
                    ),
                  );
                },
              ),
              // --- FIN DEL NUEVO BOTÓN ---
            ],
          ),
        ),
      ),
    );
  }
}

// Widget privado para el botón de Google (incluye el loading)
class _GoogleLoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Escucha el estado del BLoC
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        
        // Muestra un spinner si CUALQUIER método de login está en progreso
        if (state.status.isInProgress) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si no, muestra el botón de Google
        return ElevatedButton.icon(
          icon: const Icon(Icons.g_mobiledata, color: Colors.blue, size: 28),
          label: const Text('Continuar con Google'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.grey),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            context.read<LoginBloc>().add(const LoginWithGoogleSubmitted());
          },
        );
      },
    );
  }
}