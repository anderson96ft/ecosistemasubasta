part of 'chat_list_bloc.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object> get props => [];
}

class ChatListSubscriptionRequested extends ChatListEvent {
  const ChatListSubscriptionRequested();
}

class MarkChatAsRead extends ChatListEvent {
  final String conversationId;
  const MarkChatAsRead(this.conversationId);
}