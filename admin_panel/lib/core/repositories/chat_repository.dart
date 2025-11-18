// lib/core/repositories/chat_repository.dart

import 'package:admin_panel/core/models/conversation_model.dart';
import 'package:admin_panel/core/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obtiene un stream de todas las conversaciones de un usuario específico.
  /// Se usa en la "lista de chats".
  Stream<List<Conversation>> getConversationsForUser(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromSnapshot(doc))
          .toList();
    });
  }

  /// Obtiene un stream de todos los mensajes dentro de una conversación específica,
  /// ordenados del más antiguo al más reciente.
  Stream<List<Message>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Orden cronológico
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromSnapshot(doc)).toList();
    });
  }

  /// Obtiene un stream de un solo documento de conversación.
  /// Útil para que la pantalla de chat sepa si la conversación ha sido "cerrada".
  Stream<Conversation> getConversationDetails(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        // Si el chat no existe, lanzamos un error que el BLoC puede manejar
        // para mostrar una UI de "chat vacío" en lugar de un error fatal.
        throw Exception('Conversation with ID $conversationId does not exist.');
      }
      return Conversation.fromSnapshot(doc);
    });
  }

  /// Envía un nuevo mensaje.
  /// Esta función crea la conversación si no existe.
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required String senderId,
    // --- Datos necesarios para CREAR la conversación la primera vez ---
    required List<String> participants,
    required String productId,
    required String productModel,
    String? productImage,
  }) async {
    try {
      final now = Timestamp.now();

      final convoRef = _firestore.collection('conversations').doc(conversationId);
      final messageRef = convoRef.collection('messages').doc();

      final messageData = {
        'senderId': senderId,
        'text': text,
        'timestamp': now,
      };

      // Al enviar un mensaje, reseteamos el estado de "leído" para que el
      // otro participante vea la notificación.
      final convoData = {
        'lastMessage': text,
        'lastMessageTimestamp': now,
        'lastMessageSenderId': senderId,
        'status': 'open',
        'participants': participants,
        'productId': productId,
        'productModel': productModel,
        'productImage': productImage,
        // El admin marca como leído para el usuario, y viceversa.
        // Como el admin es el que envía, ponemos 'readByUser' a false.
        'readByUser': false,
      };

      final batch = _firestore.batch();

      batch.set(convoRef, convoData, SetOptions(merge: true));
      batch.set(messageRef, messageData);

      await batch.commit();
    } catch (e) {
      print('Error al enviar el mensaje: $e');
      rethrow;
    }
  }

  /// Marca una conversación como leída por el administrador.
  Future<void> markAsRead(String conversationId, String adminId) async {
    if (adminId.isEmpty) return;

    try {
      final convoRef = _firestore.collection('conversations').doc(conversationId);
      // El admin no tiene un campo 'readByAdmin', ya que es el punto central.
      // Lo que hacemos es marcar que el usuario (el otro) no necesita ver una
      // notificación de "no leído" por parte del admin.
      // La lógica importante está en el cliente. Para el admin, simplemente
      // actualizamos la UI localmente. Sin embargo, si tuviéramos un campo
      // 'readByAdmin', lo actualizaríamos aquí.
      // Por ahora, esta acción es principalmente para la UI del admin.
      // Si el modelo `Conversation` tuviera `readByAdmin`, la línea sería:
      // await convoRef.update({'readByAdmin': true});
      print('Lógica de marcar como leído para admin en $conversationId ejecutada.');
    } catch (e) {
      print('Error al marcar el chat como leído por el admin: $e');
    }
  }
}