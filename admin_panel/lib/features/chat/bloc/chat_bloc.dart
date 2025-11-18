// lib/features/chat/bloc/chat_bloc.dart
import 'dart:async';
import 'package:admin_panel/core/models/conversation_model.dart';
import 'package:admin_panel/core/models/message_model.dart';
import 'package:admin_panel/core/models/user_model.dart';
import 'package:admin_panel/core/repositories/chat_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart'; // O quítalo si 'login_state.dart' ya no lo usa
import 'package:rxdart/rxdart.dart'; // Importa rxdart

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final UserModel _currentUser;

  final List<String> _participants;
  final String _conversationId;
  final String _productId;
  final String _productModel;
  final String? _productImage;

  // Ya no necesitamos las variables StreamSubscription
  // StreamSubscription? _messagesSubscription;
  // StreamSubscription? _conversationSubscription;

  ChatBloc({
    required ChatRepository chatRepository,
    required UserModel currentUser,
    required String conversationId,
    required List<String> participants,
    required String productId,
    required String productModel,
    String? productImage,
  })  : _chatRepository = chatRepository,
        _currentUser = currentUser,
        _conversationId = conversationId,
        _participants = participants,
        _productId = productId,
        _productModel = productModel,
        _productImage = productImage,
        super(const ChatState()) {
    
    // Registra los manejadores de eventos
    on<LoadChat>(_onLoadChat); // <-- ESTE ES EL NUEVO MANEJADOR SEGURO
    on<SendMessage>(_onSendMessage);
    
    // Los eventos internos ya no son necesarios
    // on<_MessagesUpdated>(_onMessagesUpdated);
    // on<_ConversationStatusUpdated>(_onConversationStatusUpdated);

    // Inicia la carga automáticamente al crear el BLoC
    add(LoadChat(_conversationId));
  }

  // --- MANEJADOR _onLoadChat REESCRITO ---
  Future<void> _onLoadChat(LoadChat event, Emitter<ChatState> emit) async {
    // Emitimos 'loading' al empezar
    emit(state.copyWith(status: ChatStatus.loading));

    // Combinamos los dos streams (detalles de la conversación y lista de mensajes)
    // usando RxDart (asegúrate de tener 'rxdart' en tu pubspec.yaml)
    final combinedStream = Rx.combineLatest2(
      _chatRepository.getConversationDetails(event.conversationId),
      _chatRepository.getMessages(event.conversationId),
      (Conversation convo, List<Message> messages) => {
        'conversation': convo,
        'messages': messages,
      },
    );

    // 'emit.forEach' es la forma segura de manejar streams en BLoC.
    // Manejará automáticamente la suscripción y cancelación.
    await emit.forEach<Map<String, dynamic>>(
      combinedStream,
      onData: (data) {
        // Cada vez que cualquiera de los streams emita, actualizamos el estado
        final conversation = data['conversation'] as Conversation;
        final messages = data['messages'] as List<Message>;
        
        return state.copyWith(
          status: ChatStatus.success,
          messages: messages,
          conversationStatus: conversation.status,
        );
      },
      onError: (error, stackTrace) {
        print('Error en el stream del chat: $error');
        // Si el stream falla (ej. el chat no existe la primera vez)
        // emitimos un estado de éxito pero con valores por defecto.
        // El chat se creará al enviar el primer mensaje.
        if (state.status != ChatStatus.success) {
           return state.copyWith(
            status: ChatStatus.success, // Lo marcamos como éxito para mostrar la UI
            conversationStatus: 'open', // Asumimos 'open'
            messages: [],
          );
        }
        // Si ya estábamos en 'success', no sobrescribimos el estado
        return state;
      },
    );
  }
  // --- FIN DEL MANEJADOR REESCRITO ---

  // _onMessagesUpdated y _onConversationStatusUpdated ya no son necesarios

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (event.text.trim().isEmpty || state.conversationStatus == 'closed') {
      return;
    }

    try {
      await _chatRepository.sendMessage(
        conversationId: _conversationId,
        text: event.text.trim(),
        senderId: _currentUser.id,
        participants: _participants,
        productId: _productId,
        productModel: _productModel,
        productImage: _productImage,
      );
    } catch (e) {
      print("Error al enviar mensaje: $e");
      // Opcional: emitir un estado temporal de error de envío
      // emit(state.copyWith(errorMessage: "No se pudo enviar el mensaje."));
      // (No es necesario, ya que el estado principal no falló)
    }
  }

  // El método 'close' ya no necesita cancelar suscripciones manualmente
  // porque 'emit.forEach' lo hace por nosotros.
  @override
  Future<void> close() {
    return super.close();
  }
}