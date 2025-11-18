// lib/features/chat/presentation/screens/chat_detail_screen.dart

// ... (todos tus imports: flutter.dart, bloc, chat_bloc.dart, auth_bloc.dart, etc.) ...

import 'package:subasta/core/repositories/chat_repository.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:subasta/features/chat/bloc/chat_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' hide ChatState;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;


// --- 1. Widget Principal (Proveedor del BLoC) ---

class ChatDetailScreen extends StatelessWidget {
  // Parámetros necesarios para iniciar o unirse a un chat
  final String conversationId; // ID único (ej. "productId_userId")
  final String otherUserId; // El ID del admin O del usuario con el que chateas
  final String productId;
  final String productModel;
  final String? productImage;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.productId,
    required this.productModel,
    this.productImage,
  });

  // Constructor para cuando se abre desde una notificación.
  // Solo recibe el conversationId y establece valores temporales para los demás.
  const ChatDetailScreen.fromNotification({
    super.key,
    required this.conversationId,
  })  : otherUserId = '', // Se obtendrá del BLoC de ChatDetail
        productId = '',
        productModel = 'Mensajes', // Título temporal mientras carga
        productImage = null;

  @override
  Widget build(BuildContext context) {
    // 1. Obtiene el usuario actual (sea admin o usuario normal)
    final authUser = context.read<AuthBloc>().state.user;

    // --- ¡CORRECCIÓN! ---
    // No necesitamos 'adminUid' hardcodeado.
    // La lógica de 'participants' usa el usuario actual y el 'otherUserId'
    // que se pasó como parámetro.
    // --------------------
    final participants = [authUser.id, otherUserId];

    return BlocProvider(
      create: (context) => ChatBloc(
        chatRepository: context.read<ChatRepository>(),
        currentUser: authUser,
        conversationId: conversationId,
        // Pasa los datos necesarios para crear el chat si no existe
        participants: participants,
        productId: productId,
        productModel: productModel,
        productImage: productImage,
      ),
      child: ChatPage(
        // Pasa el nombre del producto al AppBar
        title: productModel,
      ),
    );
  }
}

// --- 2. La Vista del Chat ---
// (El resto del archivo 'ChatPage' y sus widgets permanecen exactamente igual
//  ya que solo dependen del BLoC y no de quién es el admin)

class ChatPage extends StatelessWidget {
  final String title;
  const ChatPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user.id;
    final chatUser = types.User(id: userId);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state.status == ChatStatus.loading && state.messages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ChatStatus.failure) {
            return Center(child: Text(state.errorMessage ?? 'Error al cargar chat'));
          }

          final messages = state.messages.map((msg) {
            return types.TextMessage(
              author: types.User(id: msg.senderId),
              id: msg.id,
              text: msg.text,
              createdAt: msg.timestamp.millisecondsSinceEpoch,
            );
          }).toList();

          return Chat(
            messages: messages.reversed.toList(),
            onSendPressed: (types.PartialText message) {
              context.read<ChatBloc>().add(SendMessage(message.text));
            },
            user: chatUser,
            theme: DefaultChatTheme(
              primaryColor: Theme.of(context).primaryColor,
            ),
            inputOptions: InputOptions(
              enabled: state.conversationStatus == 'open',
            ),
            customBottomWidget: state.conversationStatus == 'closed'
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey.shade300,
                    child: const Text(
                      'Esta conversación ha sido cerrada por el administrador.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}