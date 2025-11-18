// lib/features/auth/presentation/screens/phone_input_screen.dart

import 'package:subasta/core/repositories/auth_repository.dart';
import 'package:subasta/features/auth/bloc/phone_auth/phone_auth_bloc.dart';
import 'package:subasta/features/auth/presentation/screens/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PhoneInputScreen extends StatelessWidget {
  const PhoneInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PhoneAuthBloc(
        authRepository: context.read<AuthRepository>(),
      ),
      child: const PhoneInputForm(),
    );
  }
}

class PhoneInputForm extends StatefulWidget {
  const PhoneInputForm({super.key});

  @override
  State<PhoneInputForm> createState() => _PhoneInputFormState();
}

class _PhoneInputFormState extends State<PhoneInputForm> {
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Limpia cualquier estado anterior al entrar en esta pantalla.
    context.read<PhoneAuthBloc>().add(PhoneAuthReset());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicia Sesión con Teléfono')),
      body: BlocConsumer<PhoneAuthBloc, PhoneAuthState>(
        listener: (context, state) {
          // --- 1. Navegación a la pantalla OTP ---
          if (state.status == PhoneAuthStatus.codeSent) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  // Pasa el BLoC existente a la siguiente pantalla
                  value: context.read<PhoneAuthBloc>(),
                  child: OtpScreen(verificationId: state.verificationId),
                ),
              ),
            );
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
          // --- 3. Manejo de Éxito (Autocompletado) ---
          else if (state.status == PhoneAuthStatus.verificationSuccess) {
             // Si el autocompletado funciona, cierra esta pantalla
             // y vuelve a la pantalla anterior (ej. ProductDetailScreen)
             Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        builder: (context, state) {
          final isLoading = state.status == PhoneAuthStatus.loading;

          // Sincroniza el controlador con el estado (útil si se edita el estado)
          if (_phoneController.text != state.phoneNumber) {
            _phoneController.text = state.phoneNumber;
            // Mueve el cursor al final
            _phoneController.selection = TextSelection.fromPosition(
              TextPosition(offset: _phoneController.text.length),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.phone_android, size: 80, color: Colors.grey),
                  const SizedBox(height: 24),
                  const Text(
                    'Introduce tu número de teléfono',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Te enviaremos un código de verificación por SMS.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _phoneController,
                    onChanged: (phone) {
                      context
                          .read<PhoneAuthBloc>()
                          .add(PhoneNumberChanged(phone));
                    },
                    decoration: const InputDecoration(
                      labelText: 'Número de teléfono',
                      hintText: '+51 987 654 321',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed:
                        // Deshabilita el botón si está cargando o el número no es válido
                        isLoading || !state.isPhoneNumberValid
                            ? null
                            : () {
                                // Dispara el evento para enviar el código
                                context.read<PhoneAuthBloc>().add(
                                      PhoneNumberSubmitted(state.phoneNumber),
                                    );
                              },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('ENVIAR CÓDIGO'),
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