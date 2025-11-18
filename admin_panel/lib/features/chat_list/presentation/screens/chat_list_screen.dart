// lib/features/chat_list/presentation/screens/chat_list_screen.dart
import 'package:admin_panel/core/repositories/chat_repository.dart';
import 'package:admin_panel/features/auth/bloc/auth_bloc.dart';
import 'package:admin_panel/features/chat/presentation/screens/chat_detail_screen.dart'; // Importa la pantalla de chat
import 'package:admin_panel/features/chat_list/bloc/chat_list_bloc.dart';
import 'package:admin_panel/presentation/widgets/info_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  // Función auxiliar para obtener el ID del "otro" participante (el admin)
  String _getOtherParticipantId(List<String> participants, String currentUserId) {
    // Devuelve el primer ID de la lista que no sea el del usuario actual.
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '', // Devuelve vacío si no se encuentra (caso improbable)
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthBloc>().state.user.id;

    return BlocProvider(
      create: (context) => ChatListBloc(
        chatRepository: context.read<ChatRepository>(),
        authBloc: context.read<AuthBloc>(),
      )..add(const ChatListSubscriptionRequested()), // Inicia la carga
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mensajes'),
        ),
        body: BlocBuilder<ChatListBloc, ChatListState>(
          builder: (context, state) {
            if (state.status == ChatListStatus.loading || state.status == ChatListStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == ChatListStatus.failure) {
              return Center(child: Text('Error: ${state.errorMessage}'));
            }
            if (state.conversations.isEmpty) {
              return const InfoMessageWidget(
                icon: Icons.chat_bubble_outline,
                title: 'Sin mensajes',
                message: 'Cuando ganes una subasta, el administrador te contactará por aquí.',
              );
            }

            return ListView.builder(
              itemCount: state.conversations.length,
              itemBuilder: (context, index) {
                final convo = state.conversations[index];
                
                // Determina si el último mensaje fue leído por el usuario
                final bool isUnread = !convo.readByUser && convo.lastMessageSenderId != currentUserId;
                
                // Obtiene el ID del admin
                final adminId = _getOtherParticipantId(convo.participants, currentUserId);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: convo.productImage != null
                        ? NetworkImage(convo.productImage!)
                        : null,
                    child: convo.productImage == null
                        ? const Icon(Icons.image_not_supported)
                        : null,
                  ),
                  title: Text(
                    convo.productModel, // Título del chat es el nombre del producto
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    convo.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      color: isUnread ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                  trailing: Text(
                    // Formatea la fecha (ej. "10:30 AM" o "Ayer")
                    DateFormat.jm().format(convo.lastMessageTimestamp.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnread ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ),
                  onTap: () async {
                    // Navega a la pantalla de chat
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          conversationId: convo.id,
                          otherUserId: adminId, // Le pasamos el ID del admin
                          productId: convo.productId,
                          productModel: convo.productModel,
                          productImage: convo.productImage,
                        ),
                      ),
                    );
                    // Al volver, se notifica al BLoC para que actualice el estado de lectura en la UI.
                    context.read<ChatListBloc>().add(MarkChatAsRead(convo.id));
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}