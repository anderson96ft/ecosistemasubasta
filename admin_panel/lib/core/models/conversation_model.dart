// lib/core/models/conversation_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id; // Será el ID del documento (ej. "productId_userId")
  final List<String> participants;
  final String productId;
  final String productModel;
  final String? productImage;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;
  final String lastMessageSenderId;
  final bool readByAdmin;
  final bool readByUser;
  final String status; // "open" o "closed"

  const Conversation({
    required this.id,
    required this.participants,
    required this.productId,
    required this.productModel,
    this.productImage,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.lastMessageSenderId,
    required this.readByAdmin,
    required this.readByUser,
    required this.status,
  });

  factory Conversation.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>? ?? {};
    return Conversation(
      id: snap.id,
      participants: List<String>.from(data['participants'] ?? []),
      productId: data['productId'] ?? '',
      productModel: data['productModel'] ?? 'Producto no disponible',
      productImage: data['productImage'] as String?,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      readByAdmin: data['readByAdmin'] ?? false,
      readByUser: data['readByUser'] ?? false,
      status: data['status'] ?? 'closed',
    );
  }

  @override
  List<Object?> get props => [
        id,
        participants,
        productId,
        productModel,
        productImage,
        lastMessage,
        lastMessageTimestamp,
        lastMessageSenderId,
        readByAdmin,
        readByUser,
        status,
      ];
}