// lib/features/bids/bloc/bids_state.dart
import 'package:subasta/core/models/product_model.dart';
import 'package:equatable/equatable.dart';

enum BidsStatus { initial, loading, success, failure }

class BidsState extends Equatable {
  final BidsStatus status;
  final List<Product> activeBids;
  final List<Product> pendingAuctions;
  final String errorMessage;

  const BidsState({
    this.status = BidsStatus.initial,
    this.activeBids = const [],
    this.pendingAuctions = const [],
    this.errorMessage = '',
  });

  BidsState copyWith({
    BidsStatus? status,
    List<Product>? activeBids,
    List<Product>? pendingAuctions,
    String? errorMessage,
  }) {
    return BidsState(
      status: status ?? this.status,
      activeBids: activeBids ?? this.activeBids,
      pendingAuctions: pendingAuctions ?? this.pendingAuctions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object> get props => [status, activeBids, pendingAuctions, errorMessage];
}