import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// --- Versión Corregida y Actualizada del Mock de Firebase ---

void setupFirebaseAuthMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Interceptamos las llamadas al canal de 'firebase_core'.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_core'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'Firebase#initializeCore') {
        // Cuando se llama a initializeCore, devolvemos una lista de apps simuladas.
        return [
          {
            'name': '[DEFAULT]',
            'options': {},
            'isAutomaticDataCollectionEnabled': false,
            'pluginConstants': {}
          }
        ];
      }
      return null;
    },
  );
}