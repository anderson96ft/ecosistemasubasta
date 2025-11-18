// lib/features/product_detail/bloc/product_detail_state.dart
import 'package:equatable/equatable.dart';
import 'package:subasta/core/models/product_model.dart';
import 'package:subasta/core/models/bid_model.dart'; // <-- AÑADE IMPORTACIÓN

enum ProductDetailStatus { initial, loading, success, failure }

// 1. Añadimos un enum para el estado de la puja
enum BidStatus { initial, loading, success, failure }

class ProductDetailState extends Equatable {
  final List<Bid> bids; // <-- NUEVA PROPIEDAD
  final ProductDetailStatus status;
  final Product? product;
  final String errorMessage;

  // Propiedad para el ID del usuario actual, necesaria para la lógica del "dueño"
  final String currentUserId;

  // 2. Añadimos las nuevas propiedades de estado
  final BidStatus bidStatus;
  final String bidErrorMessage;

  // 3. Actualizamos el constructor
  const ProductDetailState({
    this.bids = const [], // <-- INICIALIZA
    this.status = ProductDetailStatus.initial,
    this.product,
    this.errorMessage = '',
    this.currentUserId = '',
    this.bidStatus = BidStatus.initial,
    this.bidErrorMessage = '',
  });

  // 4. Actualizamos el método copyWith
  ProductDetailState copyWith({
    ProductDetailStatus? status,
    Product? product,
    String? errorMessage,
    BidStatus? bidStatus,
    String? bidErrorMessage,
    List<Bid>? bids, // <-- AÑADE AL copyWith
    String? currentUserId,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      product: product ?? this.product,
      errorMessage: errorMessage ?? this.errorMessage,
      bidStatus: bidStatus ?? this.bidStatus,
      currentUserId: currentUserId ?? this.currentUserId,
      bidErrorMessage: bidErrorMessage ?? this.bidErrorMessage,
      bids: bids ?? this.bids, // <-- AÑADE ASIGNACIÓN
    );
  }

  // 5. Actualizamos la lista de props
  @override
  List<Object?> get props =>
      [
        status,
        product,
        bids,
        errorMessage,
        bidStatus,
        bidErrorMessage,
        currentUserId
      ];

  /// Getter para determinar si el usuario actual es el "dueño" del producto.
  /// Devuelve `true` si el usuario ganó la subasta o compró el producto.
  bool get isCurrentUserOwner {
    if (product == null || currentUserId.isEmpty) return false;

    final isAuctionWinner = (product!.status == 'finished' ||
            product!.status == 'pending_confirmation' ||
            product!.status == 'sold') &&
        product!.winnerId == currentUserId;

    final isDirectBuyer =
        product!.status == 'sold' && product!.buyerId == currentUserId;

    return isAuctionWinner || isDirectBuyer;
  }
}
