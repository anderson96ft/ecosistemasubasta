part of 'chat_list_bloc.dart';

enum ChatListStatus { initial, loading, success, failure }

class ChatListState extends Equatable {
  const ChatListState({
    this.status = ChatListStatus.initial,
    this.conversations = const [],
    this.errorMessage,
  });

  final ChatListStatus status;
  final List<Conversation> conversations;
  final String? errorMessage;

  ChatListState copyWith({
    ChatListStatus? status,
    List<Conversation>? conversations,
    String? errorMessage,
  }) {
    return ChatListState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, conversations, errorMessage];
}