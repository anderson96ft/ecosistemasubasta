// lib/features/chat/bloc/chat_event.dart
part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object> get props => [];
}

/// Se dispara desde la UI para cargar los mensajes de un chat
class LoadChat extends ChatEvent {
  final String conversationId;
  const LoadChat(this.conversationId);
}

/// Se dispara desde la UI cuando el usuario envía un mensaje
class SendMessage extends ChatEvent {
  final String text;
  const SendMessage(this.text);
}

/// Evento interno para actualizar la UI cuando llegan nuevos mensajes
class _MessagesUpdated extends ChatEvent {
  final List<Message> messages;
  const _MessagesUpdated(this.messages);
}

/// Evento interno para actualizar la UI cuando el estado de la conversación cambia (ej. "closed")
class _ConversationStatusUpdated extends ChatEvent {
  final Conversation conversation;
  const _ConversationStatusUpdated(this.conversation);
}