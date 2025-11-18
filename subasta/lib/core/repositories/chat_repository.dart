// lib/core/repositories/chat_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:subasta/core/models/conversation_model.dart'; // Asegúrate de importar tus modelos
import 'package:subasta/core/models/message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obtiene un stream de todas las conversaciones de un usuario específico.
  /// Se usa en la "lista de chats" del usuario.
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
        .orderBy('timestamp', descending: false) // Queremos el chat en orden cronológico
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
        .map((doc) => Conversation.fromSnapshot(doc));
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
      
      // 1. Referencia al documento principal de la conversación
      final convoRef = _firestore.collection('conversations').doc(conversationId);
      
      // 2. Referencia al nuevo documento de mensaje
      final messageRef = convoRef.collection('messages').doc();

      // 3. Prepara los datos del mensaje
      final messageData = {
        'senderId': senderId,
        'text': text,
        'timestamp': now,
      };

      // 4. Prepara los datos de la conversación
      // Usamos 'set' con 'merge: true' para que cree el documento si no existe,
      // o actualice el 'lastMessage' si ya existe.
      final convoData = {
        'lastMessage': text,
        'lastMessageTimestamp': now,
        'lastMessageSenderId': senderId,
        'status': 'open', // Asegura que el chat esté abierto al enviar un mensaje
        // Estos campos solo se escribirán la primera vez (gracias a merge:true)
        'participants': participants,
        'productId': productId,
        'productModel': productModel,
        'productImage': productImage,
        // TODO: Manejar 'readByAdmin' / 'readByUser'
      };

      // 5. Usa una transacción en lote (batch) para asegurar que ambas escrituras
      //    (actualizar la conversación Y añadir el mensaje) ocurran juntas.
      final batch = _firestore.batch();

      // Escritura 1: Crea/Actualiza el documento de la conversación
      batch.set(convoRef, convoData, SetOptions(merge: true));
      
      // Escritura 2: Crea el nuevo documento de mensaje
      batch.set(messageRef, messageData);

      // 6. Ejecuta el lote
      await batch.commit();
      
    } catch (e) {
      print('Error al enviar el mensaje: $e');
      // Relanza el error para que el BLoC lo maneje
      rethrow;
    }
  }

  /// Marca una conversación como leída por el usuario actual.
  Future<void> markAsRead(String conversationId, String userId) async {
    // No tiene sentido marcar como leído si no hay usuario.
    if (userId.isEmpty) return;

    try {
      final convoRef = _firestore.collection('conversations').doc(conversationId);
      // Actualizamos el campo 'readByUser' a true.
      // Este campo debe existir en tu modelo de 'Conversation' y en Firestore.
      // La lógica en ChatListScreen (`!convo.readByUser`) depende de este campo.
      await convoRef.update({'readByUser': true,});
      print('Conversación $conversationId marcada como leída por el usuario $userId.');
    } catch (e) {
      print('Error al marcar el chat como leído: $e');
      // En una app real, podrías querer registrar este error en un servicio de monitoreo.
    }
  }
}