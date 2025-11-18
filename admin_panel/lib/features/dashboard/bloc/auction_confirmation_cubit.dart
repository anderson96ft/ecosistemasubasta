// lib/features/dashboard/bloc/auction_confirmation_cubit.dart

import 'dart:async';
import 'package:admin_panel/core/models/bid_model.dart';
import 'package:admin_panel/core/models/product_model.dart';
import 'package:admin_panel/core/models/user_details_model.dart';
import 'package:admin_panel/core/repositories/auth_repository.dart';
import 'package:admin_panel/core/repositories/product_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// --- Modelo de Datos Combinado ---
// Une la información de la puja (Bid), los detalles del usuario (UserDetails),
// y un booleano que indica si el usuario tiene un historial de incidentes.
class BidderInfo extends Equatable {
  final Bid bid;
  final UserDetails userDetails;
  final bool hasIncidents;

  const BidderInfo({
    required this.bid,
    required this.userDetails,
    this.hasIncidents = false,
  });

  @override
  List<Object?> get props => [bid, userDetails, hasIncidents];
}

// --- Estado del Cubit ---
// Define cómo puede estar la UI en cualquier momento: cargando, con datos o con un error.
class AuctionConfirmationState extends Equatable {
  final List<BidderInfo> bidders;
  final bool isLoading;
  final String? error;

  const AuctionConfirmationState({
    this.bidders = const [],
    this.isLoading = true,
    this.error,
  });

  @override
  List<Object?> get props => [bidders, isLoading, error];
}

// --- El Cubit (La Lógica) ---
class AuctionConfirmationCubit extends Cubit<AuctionConfirmationState> {
  final ProductRepository _productRepository;
  final AuthRepository _authRepository;
  final Product _product;

  AuctionConfirmationCubit({
    required ProductRepository productRepository,
    required AuthRepository authRepository,
    required Product product,
  }) : _productRepository = productRepository,
       _authRepository = authRepository,
       _product = product,
       super(const AuctionConfirmationState());

  /// Carga la lista de pujas y enriquece cada una con los datos del pujador.
  Future<void> loadBidders() async {
    try {
      emit(const AuctionConfirmationState(isLoading: true));

      // 1. Obtiene la lista de todas las pujas del producto.
      final bids =
          await _productRepository.getBidsForProduct(_product.id).first;

      final List<BidderInfo> bidders = [];
      // 2. Itera sobre cada puja para obtener la información del pujador.
      for (final bid in bids) {
        // Obtenemos los detalles y el estado de incidentes en paralelo para cada usuario.
        final results = await Future.wait([
          _authRepository.getUserDetails(bid.userId),
          _authRepository.userHasIncidents(bid.userId),
        ]);

        // 3. Combina toda la información en un solo objeto BidderInfo.
        bidders.add(
          BidderInfo(
            bid: bid,
            userDetails: results[0] as UserDetails? ?? UserDetails.empty(),
            hasIncidents: results[1] as bool? ?? false,
          ),
        );
      }

      emit(AuctionConfirmationState(bidders: bidders, isLoading: false));
    } catch (e) {
      emit(AuctionConfirmationState(error: e.toString(), isLoading: false));
    }
  }

  /// Llama a la Cloud Function para reportar un incidente y luego anular la puja.
  Future<void> reportAndAnnulBid(BidderInfo bidder) async {
    // Mantenemos los datos actuales pero activamos el loading para dar feedback.
    emit(AuctionConfirmationState(bidders: state.bidders, isLoading: true));
    try {
      const reason =
          'Oferta no confirmada por el administrador tras contacto telefónico.';

      // Primero reporta el incidente contra el usuario.
      await _productRepository.reportIncident(
        reportedUserId: bidder.userDetails.uid,
        productId: _product.id,
        productModel: _product.model,
        bidAmount: bidder.bid.amount,
        reason: reason,
      );

      // Luego, anula la puja para promover al siguiente en la lista.
      await _productRepository.annulBid(
        productId: _product.id,
        highestBidId: bidder.bid.id, // Pasamos el ID de la puja a eliminar
      );

      // Después de la acción, recargamos los datos para que la UI se actualice al instante.
      await loadBidders();
    } catch (e) {
      print('Error al reportar y anular: $e');
      emit(
        AuctionConfirmationState(
          error: 'Error al anular la puja: $e',
          isLoading: false,
        ),
      );
    }
  }

  /// Llama a la Cloud Function para confirmar la venta final.
  Future<void> confirmSale() async {
    emit(const AuctionConfirmationState(isLoading: true));
    try {
      await _productRepository.confirmSale(productId: _product.id);
      // No necesitamos emitir un estado de éxito, ya que la UI se encargará de
      // cerrar esta pantalla y el Dashboard se actualizará automáticamente.
    } catch (e) {
      print('Error al confirmar la venta: $e');
      emit(
        AuctionConfirmationState(
          error: 'Error al confirmar la venta: $e',
          isLoading: false,
        ),
      );
    }
  }
}
