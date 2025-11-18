// lib/features/chat_list/bloc/chat_list_bloc.dart
import 'dart:async';
import 'package:subasta/core/models/conversation_model.dart';
import 'package:subasta/core/repositories/chat_repository.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart'; // Para obtener el ID del usuario
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'chat_list_event.dart';
part 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatRepository _chatRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _conversationsSubscription;
  late final String _userId; // Almacena el ID del usuario actual

  ChatListBloc({
    required ChatRepository chatRepository,
    required AuthBloc authBloc,
  })  : _chatRepository = chatRepository,
        _authBloc = authBloc,
        super(const ChatListState()) {
    
    // Obtiene el ID del usuario del AuthBloc al iniciar
    _userId = _authBloc.state.user.id;

    on<ChatListSubscriptionRequested>(_onSubscriptionRequested);
    on<_ChatListUpdated>(_onChatListUpdated);
  }

  void _onSubscriptionRequested(
    ChatListSubscriptionRequested event,
    Emitter<ChatListState> emit,
  ) {
    // Si no hay usuario (aunque esta pantalla debería estar protegida), no hace nada
    if (_userId.isEmpty) {
      return emit(state.copyWith(status: ChatListStatus.success));
    }

    emit(state.copyWith(status: ChatListStatus.loading));
    _conversationsSubscription?.cancel();
    
    _conversationsSubscription = _chatRepository
        .getConversationsForUser(_userId) // Llama al método del repositorio
        .listen(
      (conversations) {
        // Cuando llegan datos, dispara el evento interno
        add(_ChatListUpdated(conversations));
      },
      onError: (error) {
        emit(state.copyWith(
          status: ChatListStatus.failure,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  void _onChatListUpdated(
    _ChatListUpdated event,
    Emitter<ChatListState> emit,
  ) {
    emit(state.copyWith(
      status: ChatListStatus.success,
      conversations: event.conversations,
    ));
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    return super.close();
  }
}