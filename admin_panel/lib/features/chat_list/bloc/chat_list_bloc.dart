import 'dart:async';

import 'package:admin_panel/core/models/conversation_model.dart';
import 'package:admin_panel/core/repositories/chat_repository.dart';
import 'package:admin_panel/features/auth/bloc/auth_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'chat_list_event.dart';
part 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatRepository _chatRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _conversationsSubscription;

  ChatListBloc({
    required ChatRepository chatRepository,
    required AuthBloc authBloc,
  })  : _chatRepository = chatRepository,
        _authBloc = authBloc,
        super(const ChatListState()) {
    on<ChatListSubscriptionRequested>(_onSubscriptionRequested);
    on<MarkChatAsRead>(_onMarkChatAsRead);
  }

  Future<void> _onSubscriptionRequested(
    ChatListSubscriptionRequested event,
    Emitter<ChatListState> emit,
  ) async {
    emit(state.copyWith(status: ChatListStatus.loading));

    await _conversationsSubscription?.cancel();
    _conversationsSubscription = _chatRepository
        .getConversationsForUser(_authBloc.state.user.id)
        .listen(
      (conversations) {
        emit(state.copyWith(
          status: ChatListStatus.success,
          conversations: conversations,
        ));
      },
      onError: (error) {
        emit(state.copyWith(
            status: ChatListStatus.failure, errorMessage: error.toString()));
      },
    );
  }

  Future<void> _onMarkChatAsRead(
    MarkChatAsRead event,
    Emitter<ChatListState> emit,
  ) async {
    // Llama al repositorio para cualquier lógica de backend (aunque en el admin sea solo un print)
    await _chatRepository.markAsRead(event.conversationId, _authBloc.state.user.id);
    // No es necesario emitir un nuevo estado aquí, porque la suscripción
    // al stream de conversaciones se encargará de actualizar la UI si los datos cambian.
    // Si quisiéramos una actualización instantánea en la UI, podríamos actualizar el estado localmente.
  }
}