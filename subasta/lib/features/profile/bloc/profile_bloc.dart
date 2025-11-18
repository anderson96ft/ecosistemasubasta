// lib/features/profile/bloc/profile_bloc.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:subasta/core/models/product_model.dart';
import 'package:subasta/core/repositories/product_repository.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProductRepository _productRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _profileSubscription;

  ProfileBloc({
    required ProductRepository productRepository,
    required AuthBloc authBloc,
  }) : _productRepository = productRepository,
       _authBloc = authBloc,
       super(const ProfileState()) {
    on<ProfileSubscriptionRequested>(_onSubscriptionRequested);
    on<ProfileDataUpdated>(_onProfileDataUpdated);
    on<SortHistoryRequested>(_onSortHistoryRequested); // Registra el nuevo manejador
  }

  void _onSubscriptionRequested(
    ProfileSubscriptionRequested event,
    Emitter<ProfileState> emit,
  ) {
    final userId = _authBloc.state.user.id;
    if (userId.isEmpty) {
      // Si no hay usuario, emitimos un estado de éxito con listas vacías.
      emit(state.copyWith(status: ProfileStatus.success));
      return;
    }

    emit(state.copyWith(status: ProfileStatus.loading));
    _profileSubscription?.cancel();

    // --- LÓGICA PRINCIPAL CORREGIDA: Usamos combineLatest4 ---
    _profileSubscription = Rx.combineLatest4(
      // 1. Stream de pujas activas donde el usuario va ganando
      _productRepository.getActiveBidsForUser(userId),
      // 2. Stream de subastas que el usuario ha ganado
      _productRepository.getWonAuctionsForUser(userId),
      // 3. Stream de compras directas que el usuario ha hecho
      _productRepository.getDirectPurchasesForUser(userId),
      // 4. Stream de subastas pendientes en las que el usuario participó
      _productRepository.getPendingConfirmationAuctionsForUser(userId),

      // La función combinadora ahora recibe 4 listas de productos
      (
        List<Product> activeBids,
        List<Product> wonAuctions,
        List<Product> directPurchases,
        List<Product> pendingAuctions,
      ) {
        // Empaquetamos todo en un mapa para pasarlo al evento.
        return {
          'activeBids': activeBids,
          'wonAuctions': wonAuctions, // Pasamos las listas por separado
          'directPurchases': directPurchases,
          'pendingAuctions': pendingAuctions,
        };
      },
    ).listen(
      (data) => add(ProfileDataUpdated(data)),
      // Manejamos los errores de forma segura
      onError:
          (error) => emit(
            state.copyWith(
              status: ProfileStatus.failure,
              errorMessage: error.toString(),
            ),
          ),
    );
  }

  void _onProfileDataUpdated(
    ProfileDataUpdated event,
    Emitter<ProfileState> emit,
  ) {
    // Desempaquetamos los datos del mapa y los asignamos al estado.
    emit(
      state.copyWith(
        status: ProfileStatus.success,
        activeBids: event.data['activeBids'] as List<Product>,
        wonAuctions: event.data['wonAuctions'] as List<Product>,
        directPurchases: event.data['directPurchases'] as List<Product>,
        pendingAuctions: event.data['pendingAuctions'] as List<Product>,
      ),
    );
    // Después de actualizar, aplicamos la ordenación actual
    add(SortHistoryRequested(state.sortOption));
  }

  // --- NUEVO MANEJADOR PARA LA ORDENACIÓN ---
  void _onSortHistoryRequested(
    SortHistoryRequested event,
    Emitter<ProfileState> emit,
  ) {
    final sortedWonAuctions = List<Product>.from(state.wonAuctions);
    final sortedDirectPurchases = List<Product>.from(state.directPurchases);

    // Función de comparación genérica
    int Function(Product, Product) compareFunction;

    switch (event.sortOption) {
      case SortOption.name:
        compareFunction = (a, b) => a.model.compareTo(b.model);
        break;
      case SortOption.price:
        // Compara por precio final (currentPrice para subasta, fixedPrice para compra)
        compareFunction = (a, b) => (b.currentPrice ?? b.fixedPrice ?? 0)
            .compareTo(a.currentPrice ?? a.fixedPrice ?? 0);
        break;
      case SortOption.date:
      default:
        // Usamos una fecha de fallback muy antigua para asegurar una ordenación estable
        // si un producto no tuviera fecha, evitando el uso de Timestamp.now().
        final fallbackDate = Timestamp.fromMillisecondsSinceEpoch(0);
        compareFunction = (a, b) => (b.endTime ?? b.createdAt ?? fallbackDate)
            .compareTo(a.endTime ?? a.createdAt ?? fallbackDate);
        break;
    }

    sortedWonAuctions.sort(compareFunction);
    sortedDirectPurchases.sort(compareFunction);

    emit(state.copyWith(
      wonAuctions: sortedWonAuctions,
      directPurchases: sortedDirectPurchases,
      sortOption: event.sortOption,
    ));
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}
