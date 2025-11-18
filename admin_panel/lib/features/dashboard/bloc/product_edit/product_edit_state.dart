// lib/features/dashboard/bloc/product_edit/product_edit_state.dart

import 'package:equatable/equatable.dart';

enum ProductEditStatus { initial, loading, success, failure }

class ProductEditState extends Equatable {
  final ProductEditStatus status;
  final String? errorMessage;

  const ProductEditState({
    this.status = ProductEditStatus.initial,
    this.errorMessage,
  });

  ProductEditState copyWith({
    ProductEditStatus? status,
    String? errorMessage,
  }) {
    return ProductEditState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}