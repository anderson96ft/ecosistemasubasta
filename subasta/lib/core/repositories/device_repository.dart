// lib/core/repositories/device_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DeviceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  DeviceRepository({FirebaseFirestore? firestore, FirebaseMessaging? messaging})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  /// Obtiene el token FCM del dispositivo actual y lo guarda en Firestore
  /// asociado al ID del usuario.
  Future<void> saveDeviceToken({required String userId}) async {
    try {
      // 1. Obtiene el token único del dispositivo.
      // Este token puede cambiar si el usuario reinstala la app o cambia de dispositivo.
      final String? token = await _messaging.getToken();

      if (token == null) {
        print('Error: No se pudo obtener el token FCM.');
        return;
      }

      print('Token FCM obtenido: $token');

      // 2. Define la ruta en Firestore.
      // Crearemos un documento por cada dispositivo, usando el token como ID.
      // Esto previene duplicados y facilita la eliminación.
      final deviceRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(token);

      // 3. Guarda el token junto con información útil.
      // 'lastSeen' nos permite en el futuro eliminar tokens de dispositivos inactivos.
      await deviceRef.set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });

      print('Token FCM guardado para el usuario: $userId');

    } catch (e) {
      print('Ocurrió un error al guardar el token del dispositivo: $e');
      // En una app real, podrías registrar este error en un servicio de monitoreo.
    }
  }
}