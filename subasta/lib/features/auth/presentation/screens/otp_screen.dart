// lib/features/auth/presentation/screens/otp_screen.dart

import 'dart:async';
import 'package:subasta/features/auth/bloc/phone_auth/phone_auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  Timer? _timer;
  int _start = 60; // Temporizador de 60 segundos
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
    // Añadimos el print de depuración que teníamos antes
    print('OtpScreen recibió verificationId: ${widget.verificationId}');
  }

  void startTimer() {
    setState(() {
      _canResend = false;
      _start = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_start == 0) {
        if (mounted) {
          setState(() {
            _canResend = true;
            timer.cancel();
          });
        }
      } else {
         if (mounted) {
           setState(() {
            _start--;
          });
         }
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar Número')),
      body: BlocConsumer<PhoneAuthBloc, PhoneAuthState>(
        listener: (context, state) {
          // --- 1. Manejo de Éxito ---
          if (state.status == PhoneAuthStatus.verificationSuccess) {
            // Si el login es exitoso, cierra todas las pantallas de auth
            // y vuelve a la pantalla original (ej. ProductDetailScreen o NavScreen)
            Navigator.of(context).popUntil((route) => route.isFirst);
          } 
          // --- 2. Manejo de Errores ---
          else if (state.status == PhoneAuthStatus.verificationFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == PhoneAuthStatus.loading;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Introduce el código de 6 dígitos',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      children: [
                        const TextSpan(text: 'Lo hemos enviado a '),
                        TextSpan(
                          text: state.phoneNumber, // Obtiene el número del estado del BLoC
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'Código de Verificación',
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    enabled: !isLoading,
                    style: const TextStyle(fontSize: 24, letterSpacing: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () {
                                if (_otpController.text.length == 6) {
                                  // Dispara el evento para verificar el código
                                  context.read<PhoneAuthBloc>().add(
                                        SmsCodeSubmitted(_otpController.text.trim()),
                                      );
                                }
                              },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('VERIFICAR Y CONTINUAR'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿No recibiste el código? "),
                      TextButton(
                        onPressed:
                            _canResend && !isLoading
                                ? () {
                                    // Dispara el evento para reenviar el código
                                    context.read<PhoneAuthBloc>().add(
                                          PhoneNumberSubmitted(state.phoneNumber),
                                        );
                                    startTimer(); // Reinicia el contador
                                  }
                                : null,
                        child: Text(
                          _canResend ? 'Reenviar' : 'Reenviar en $_start s',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}