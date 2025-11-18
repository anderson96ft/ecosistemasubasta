// lib/features/product_detail/bloc/product_detail_bloc.dart

import 'dart:async';
import 'package:subasta/core/models/bid_model.dart';
import 'package:subasta/core/models/product_model.dart';
import 'package:subasta/core/repositories/product_repository.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:subasta/features/auth/bloc/auth_state.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:rxdart/rxdart.dart';

import 'product_detail_event.dart';
import 'product_detail_state.dart';

// --- Eventos Internos (Públicos) ---
class ProductDataUpdated extends ProductDetailEvent {
  final Product product;
  final List<Bid> bids;
  const ProductDataUpdated(this.product, this.bids);
}

class ProductDataFailed extends ProductDetailEvent {
  final Object error;
  const ProductDataFailed(this.error);
}

// --- El BLoC ---
class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final ProductRepository _productRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _dataSubscription;

  ProductDetailBloc({
    required ProductRepository productRepository,
    required AuthBloc authBloc,
  }) : _productRepository = productRepository,
       _authBloc = authBloc,
       super(ProductDetailState(
         currentUserId: authBloc.state.user.id, // Pasa el ID del usuario al estado inicial
       )) {
    on<ProductDetailSubscriptionRequested>(_onSubscriptionRequested);
    on<ProductDataUpdated>(_onDataUpdated);
    on<ProductDataFailed>(_onDataFailed);
    // Registramos los manejadores que estaban vacíos
    on<BidSubmitted>(_onBidSubmitted);
    on<BuyNowSubmitted>(_onBuyNowSubmitted);
  }

  void _onSubscriptionRequested(
    ProductDetailSubscriptionRequested event,
    Emitter<ProductDetailState> emit,
  ) {
    final isAuthenticated = _authBloc.state.status == AuthStatus.authenticated;

    emit(state.copyWith(status: ProductDetailStatus.loading));
    _dataSubscription?.cancel();

    if (isAuthenticated) {
      _dataSubscription = Rx.combineLatest2(
        _productRepository.getProductById(event.productId),
        _productRepository.getBidsForProduct(event.productId),
        (Product p, List<Bid> b) => {'product': p, 'bids': b},
      ).listen(
        (data) => add(
          ProductDataUpdated(
            data['product'] as Product,
            data['bids'] as List<Bid>,
          ),
        ),
        onError: (error) => add(ProductDataFailed(error)),
      );
    } else {
      _dataSubscription = _productRepository
          .getProductById(event.productId)
          .listen(
            (product) => add(ProductDataUpdated(product, const [])),
            onError: (error) => add(ProductDataFailed(error)),
          );
    }
  }

  void _onDataUpdated(
    ProductDataUpdated event,
    Emitter<ProductDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: ProductDetailStatus.success,
        product: event.product,
        bids: event.bids,
      ),
    );
  }

  void _onDataFailed(
    ProductDataFailed event,
    Emitter<ProductDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: ProductDetailStatus.failure,
        errorMessage: event.error.toString(),
      ),
    );
  }

  // ========================================================================
  // ===                  MÉTODO _onBidSubmitted COMPLETO                  ===
  // ========================================================================
  Future<void> _onBidSubmitted(
    BidSubmitted event,
    Emitter<ProductDetailState> emit,
  ) async {
    if (state.product == null) return;

    emit(state.copyWith(bidStatus: BidStatus.loading));

    try {
      await _productRepository.placeBid(
        productId: state.product!.id,
        amount: event.amount,
      );
      // Emitimos 'success' y luego reseteamos a 'initial' para futuras acciones.
      emit(state.copyWith(bidStatus: BidStatus.success));
      emit(state.copyWith(bidStatus: BidStatus.initial));
    } on FirebaseFunctionsException catch (e) {
      emit(
        state.copyWith(
          bidStatus: BidStatus.failure,
          bidErrorMessage: e.message,
        ),
      );
      emit(state.copyWith(bidStatus: BidStatus.initial, bidErrorMessage: ''));
    } catch (e) {
      emit(
        state.copyWith(
          bidStatus: BidStatus.failure,
          bidErrorMessage: e.toString(),
        ),
      );
      emit(state.copyWith(bidStatus: BidStatus.initial, bidErrorMessage: ''));
    }
  }

  // ========================================================================
  // ===                  MÉTODO _onBuyNowSubmitted COMPLETO                 ===
  // ========================================================================
  Future<void> _onBuyNowSubmitted(
    BuyNowSubmitted event,
    Emitter<ProductDetailState> emit,
  ) async {
    if (state.product == null) return;

    emit(state.copyWith(bidStatus: BidStatus.loading));

    try {
      await _productRepository.buyNow(productId: state.product!.id);
      emit(state.copyWith(bidStatus: BidStatus.success));
      // No reseteamos a 'initial' aquí porque la UI navegará hacia atrás en caso de éxito.
    } on FirebaseFunctionsException catch (e) {
      emit(
        state.copyWith(
          bidStatus: BidStatus.failure,
          bidErrorMessage: e.message,
        ),
      );
      emit(state.copyWith(bidStatus: BidStatus.initial, bidErrorMessage: ''));
    } catch (e) {
      emit(
        state.copyWith(
          bidStatus: BidStatus.failure,
          bidErrorMessage: e.toString(),
        ),
      );
      emit(state.copyWith(bidStatus: BidStatus.initial, bidErrorMessage: ''));
    }
  }

  @override
  Future<void> close() {
    _dataSubscription?.cancel();
    return super.close();
  }
}
