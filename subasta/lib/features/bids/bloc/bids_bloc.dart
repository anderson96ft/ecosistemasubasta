// lib/features/bids/bloc/bids_bloc.dart

import 'dart:async';
import 'package:subasta/core/models/product_model.dart';
import 'package:subasta/core/repositories/product_repository.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'bids_event.dart';
import 'bids_state.dart';

class BidsBloc extends Bloc<BidsEvent, BidsState> {
  final ProductRepository _productRepository;
  final AuthBloc _authBloc;
  StreamSubscription? _bidsSubscription;

  BidsBloc({
    required ProductRepository productRepository,
    required AuthBloc authBloc,
  }) : _productRepository = productRepository,
       _authBloc = authBloc,
       super(const BidsState()) {
    on<BidsSubscriptionRequested>(_onSubscriptionRequested);
    // --- MANEJADOR CORREGIDO ---
    on<BidsDataUpdated>(_onBidsDataUpdated);
  }

  void _onSubscriptionRequested(
    BidsSubscriptionRequested event,
    Emitter<BidsState> emit,
  ) {
    final userId = _authBloc.state.user.id;
    if (userId.isEmpty) {
      emit(state.copyWith(status: BidsStatus.success));
      return;
    }

    emit(state.copyWith(status: BidsStatus.loading));
    _bidsSubscription?.cancel();

    _bidsSubscription = Rx.combineLatest2(
      _productRepository.getActiveBidsForUser(userId),
      _productRepository.getPendingConfirmationAuctionsForUser(userId),
      (List<Product> activeBids, List<Product> pendingAuctions) => {
        'activeBids': activeBids,
        'pendingAuctions': pendingAuctions,
      },
    ).listen(
      // --- EVENTO CORREGIDO ---
      (data) => add(BidsDataUpdated(data)),
      onError:
          (error) => emit(
            state.copyWith(
              status: BidsStatus.failure,
              errorMessage: error.toString(),
            ),
          ),
    );
  }

  // --- MANEJADOR CORREGIDO ---
  void _onBidsDataUpdated(BidsDataUpdated event, Emitter<BidsState> emit) {
    emit(
      state.copyWith(
        status: BidsStatus.success,
        activeBids: event.data['activeBids'] as List<Product>,
        pendingAuctions: event.data['pendingAuctions'] as List<Product>,
      ),
    );
  }

  @override
  Future<void> close() {
    _bidsSubscription?.cancel();
    return super.close();
  }
}
