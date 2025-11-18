// lib/features/purchases/bloc/purchases_state.dart
import 'package:subasta/core/models/product_model.dart';
import 'package:equatable/equatable.dart';

enum PurchasesStatus { initial, loading, success, failure }

class PurchasesState extends Equatable {
  final PurchasesStatus status;
  final List<Product> purchaseHistory;
  final String errorMessage;

  const PurchasesState({
    this.status = PurchasesStatus.initial,
    this.purchaseHistory = const [],
    this.errorMessage = '',
  });

  PurchasesState copyWith({
    PurchasesStatus? status,
    List<Product>? purchaseHistory,
    String? errorMessage,
  }) {
    return PurchasesState(
      status: status ?? this.status,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object> get props => [status, purchaseHistory, errorMessage];
}