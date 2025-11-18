// lib/features/product_detail/bloc/product_detail_event.dart

import 'package:subasta/core/models/bid_model.dart';
import 'package:subasta/core/models/product_model.dart';
import 'package:equatable/equatable.dart';

abstract class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();
  @override
  List<Object> get props => [];
}

// --- Eventos de la UI ---
class ProductDetailSubscriptionRequested extends ProductDetailEvent {
  final String productId;
  const ProductDetailSubscriptionRequested(this.productId);
}

class BidSubmitted extends ProductDetailEvent {
  final double amount;
  const BidSubmitted(this.amount);
}

class BuyNowSubmitted extends ProductDetailEvent {}


// --- Eventos Internos (Públicos) para el BLoC ---

// Se añade cuando los datos del stream (producto y pujas) llegan correctamente.
class ProductDataUpdated extends ProductDetailEvent {
  final Product product;
  final List<Bid> bids;
  const ProductDataUpdated(this.product, this.bids);
}

// Se añade cuando el stream lanza un error.
class ProductDataFailed extends ProductDetailEvent {
  final Object error;
  const ProductDataFailed(this.error);
}