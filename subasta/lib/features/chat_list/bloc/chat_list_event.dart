// lib/features/chat_list/bloc/chat_list_event.dart
part of 'chat_list_bloc.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();
  @override
  List<Object> get props => [];
}

/// Se dispara desde la UI para suscribirse a las conversaciones del usuario
class ChatListSubscriptionRequested extends ChatListEvent {
  const ChatListSubscriptionRequested();
}

/// Evento interno para actualizar el estado cuando llegan nuevos chats
class _ChatListUpdated extends ChatListEvent {
  final List<Conversation> conversations;
  const _ChatListUpdated(this.conversations);
}