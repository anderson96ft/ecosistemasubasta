// lib/features/chat/bloc/chat_state.dart
part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, success, failure }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<Message> messages;
  final String conversationStatus; // "open" o "closed"
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.conversationStatus = 'open', // Asume 'open' por defecto
    this.errorMessage,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    String? conversationStatus,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      conversationStatus: conversationStatus ?? this.conversationStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, messages, conversationStatus, errorMessage];
}