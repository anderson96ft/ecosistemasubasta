// lib/features/dashboard/bloc/product_list_event.dart
import 'package:equatable/equatable.dart';

abstract class ProductListEvent extends Equatable {
  const ProductListEvent();
  @override
  List<Object> get props => [];
}

class ProductListSubscriptionRequested extends ProductListEvent {}

class ProductDeleteRequested extends ProductListEvent {
  final String productId;
  const ProductDeleteRequested(this.productId);
}
