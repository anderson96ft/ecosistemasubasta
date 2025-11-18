// lib/core/services/notification_service.dart

import 'package:subasta/core/navigation/navigator_key.dart';
import 'package:subasta/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:subasta/features/product_detail/presentation/screens/product_detail_screen.dart';
// TODO: Importa tu pantalla de chat cuando la tengas
// import 'package:subasta/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Notificación en Background RECIBIDA: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Función auxiliar para navegar a la pantalla de producto
  void _navigateToProduct(String? productId) {
    if (productId == null) {
       print('DEBUG: _navigateToProduct: ID de producto nulo, no se puede navegar.');
       return;
    }
    print('DEBUG: _navigateToProduct: Navegando al producto $productId');
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: productId),
      ),
    );
  }

  // ¡NUEVA FUNCIÓN AUXILIAR PARA NAVEGAR AL CHAT!
  void _navigateToChat(String? conversationId, String? productId) {
     if (conversationId == null) {
       print('DEBUG: _navigateToChat: ID de conversación nulo, intentando fallback a producto $productId.');
       _navigateToProduct(productId); // Fallback si no hay ID de chat
       return;
     }
    
    print('DEBUG: _navigateToChat: Navegando al chat $conversationId');
    
    // La notificación de chat no incluye todos los datos del producto.
    // La pantalla de chat debe ser capaz de funcionar solo con el conversationId
    // y obtener el resto de la información por sí misma si es necesario.
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen.fromNotification(
          conversationId: conversationId,
        ),
      ),
    );
  }

  // Función unificada para manejar el toque de la notificación
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    print("DEBUG: _handleNotificationTap: El usuario tocó la notificación. Data: $data");

    // Damos prioridad al ID de la conversación
    if (data['conversationId'] != null) {
      _navigateToChat(data['conversationId'], data['productId']);
    } 
    // Si no es un chat, comprobamos si es una notificación de producto
    else if (data['productId'] != null) {
      _navigateToProduct(data['productId']);
    } else {
      print('DEBUG: _handleNotificationTap: La notificación no tiene "conversationId" ni "productId" en sus datos.');
    }
  }


  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // --- MANEJO DE NOTIFICACIÓN TERMINADA (APP CERRADA) ---
    // Comprueba si la app se abrió desde una notificación.
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // --- MANEJO DE NOTIFICACIÓN EN PRIMER PLANO (APP ABIERTA) ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // --- INICIO DE DEBUG ---
      print('================================================');
      print('DEBUG: ¡onMessage (Primer Plano) RECIBIDO!');
      print('DEBUG: Título: ${message.notification?.title}');
      print('DEBUG: Cuerpo: ${message.notification?.body}');
      print('DEBUG: Datos (Data): ${message.data}');
      // --- FIN DE DEBUG ---

      // Usamos la clave global para obtener el contexto de forma segura
      final context = navigatorKey.currentContext;

      // --- DEBUG DE CONDICIONES ---
      if (message.notification == null) {
        print('DEBUG: FALLO DE SNACKBAR - message.notification es null.');
        print('DEBUG: (Esto pasa si la notificación push solo tiene campo "data" y no "notification")');
      }
      if (context == null) {
        print('DEBUG: FALLO DE SNACKBAR - navigatorKey.currentContext es null.');
        print('DEBUG: (Esto NO debería pasar si la app está en primer plano)');
      }
      // --- FIN DE DEBUG ---

      // --- INICIO DE LA MODIFICACIÓN ---
      // Leemos el título y el cuerpo desde el bloque 'data'
      final title = message.data['title'] as String?;
      final body = message.data['body'] as String?;

      if (body != null && context != null) {
        // --- DEBUG DE ACCIÓN ---
        print('DEBUG: ¡Mostrando SnackBar ahora!');
        // --- FIN DE DEBUG ---
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body), // Usamos el cuerpo del bloque 'data'
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () {
                // --- DEBUG DE CLIC ---
                print('DEBUG: Botón "Ver" del SnackBar presionado.');
                // --- FIN DE DEBUG ---
                _handleNotificationTap(message);
              },
            ),
          ),
        );
      }
      // --- FIN DE LA MODIFICACIÓN ---
    });

    // --- MANEJO DE NOTIFICACIÓN EN SEGUNDO PLANO (APP ABIERTA PERO MINIMIZADA) ---
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
}