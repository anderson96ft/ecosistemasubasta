// lib/features/dashboard/bloc/product_edit/product_edit_event.dart

import 'package:equatable/equatable.dart';

abstract class ProductEditEvent extends Equatable {
  const ProductEditEvent();
  @override
  List<Object?> get props => [];
}

class ProductSaveRequested extends ProductEditEvent {
  final Map<String, dynamic> productData;
  final String? productId;

  const ProductSaveRequested({required this.productData, this.productId});
  @override
  List<Object?> get props => [productData, productId];
}