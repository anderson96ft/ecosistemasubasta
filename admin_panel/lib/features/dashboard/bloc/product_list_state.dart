// lib/features/dashboard/bloc/product_list_state.dart
import 'package:admin_panel/core/models/product_model.dart';
import 'package:equatable/equatable.dart';

enum ProductListStatus { initial, loading, success, failure }

class ProductListState extends Equatable {
  final ProductListStatus status;
  final List<Product> products;
  final String errorMessage;

  const ProductListState({
    this.status = ProductListStatus.initial,
    this.products = const [],
    this.errorMessage = '',
  });

  ProductListState copyWith({
    ProductListStatus? status,
    List<Product>? products,
    String? errorMessage,
  }) {
    return ProductListState(
      status: status ?? this.status,
      products: products ?? this.products,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object> get props => [status, products, errorMessage];
}