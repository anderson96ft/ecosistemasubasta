// lib/features/dashboard/bloc/product_edit/product_edit_bloc.dart

import 'package:admin_panel/core/repositories/product_repository.dart';
import 'package:admin_panel/features/dashboard/bloc/product_edit/product_edit_event.dart';
import 'package:admin_panel/features/dashboard/bloc/product_edit/product_edit_state.dart';
import 'package:bloc/bloc.dart';

class ProductEditBloc extends Bloc<ProductEditEvent, ProductEditState> {
  final ProductRepository _productRepository;

  ProductEditBloc({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(const ProductEditState()) {
    on<ProductSaveRequested>(_onProductSaveRequested);
  }

  Future<void> _onProductSaveRequested(
    ProductSaveRequested event,
    Emitter<ProductEditState> emit,
  ) async {
    emit(state.copyWith(status: ProductEditStatus.loading));
    try {
      await _productRepository.saveProduct(
        productId: event.productId,
        productData: event.productData,
      );
      emit(state.copyWith(status: ProductEditStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: ProductEditStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}