// lib/features/purchases/bloc/purchases_bloc.dart
import 'dart:async';
import 'package:subasta/core/models/product_model.dart';
import 'package:subasta/core/repositories/product_repository.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'purchases_event.dart';
import 'purchases_state.dart';

class PurchasesBloc extends Bloc<PurchasesEvent, PurchasesState> {
  final ProductRepository _productRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _purchasesSubscription;

  PurchasesBloc({
    required ProductRepository productRepository,
    required AuthBloc authBloc,
  })  : _productRepository = productRepository,
        _authBloc = authBloc,
        super(const PurchasesState()) {
    on<PurchasesSubscriptionRequested>(_onSubscriptionRequested);
    on<PurchasesDataUpdated>(_onPurchasesDataUpdated);
  }

  void _onSubscriptionRequested(
    PurchasesSubscriptionRequested event,
    Emitter<PurchasesState> emit,
  ) {
    final userId = _authBloc.state.user.id;
    if (userId.isEmpty) {
      emit(state.copyWith(status: PurchasesStatus.success));
      return;
    }

    emit(state.copyWith(status: PurchasesStatus.loading));
    _purchasesSubscription?.cancel();

    _purchasesSubscription = Rx.combineLatest2(
      _productRepository.getWonAuctionsForUser(userId),
      _productRepository.getDirectPurchasesForUser(userId),
      // La función combinadora une las dos listas en una sola
      (List<Product> wonAuctions, List<Product> directPurchases) => 
          [...wonAuctions, ...directPurchases],
    ).listen(
      (data) => add(PurchasesDataUpdated(data)),
      onError: (error) => emit(state.copyWith(status: PurchasesStatus.failure, errorMessage: error.toString())),
    );
  }

  void _onPurchasesDataUpdated(
    PurchasesDataUpdated event,
    Emitter<PurchasesState> emit,
  ) {
    // La data ya es la lista combinada
    final purchaseHistory = event.data as List<Product>;
    // Opcional: ordenar la lista por fecha si tuvieras un campo 'completedAt'
    
    emit(state.copyWith(
      status: PurchasesStatus.success,
      purchaseHistory: purchaseHistory,
    ));
  }

  @override
  Future<void> close() {
    _purchasesSubscription?.cancel();
    return super.close();
  }
}