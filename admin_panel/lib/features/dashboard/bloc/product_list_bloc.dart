// lib/features/dashboard/bloc/product_list_bloc.dart
import 'dart:async';
import 'package:admin_panel/core/models/product_model.dart';
import 'package:admin_panel/core/repositories/product_repository.dart';
import 'package:bloc/bloc.dart';
import 'product_list_event.dart';
import 'product_list_state.dart';

// Evento interno para pasar los datos del stream de forma segura
class _ProductsUpdated extends ProductListEvent {
  final List<Product> products;
  const _ProductsUpdated(this.products);
}

class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  final ProductRepository _productRepository;
  StreamSubscription? _productsSubscription;

  ProductListBloc({required ProductRepository productRepository})
    : _productRepository = productRepository,
      super(const ProductListState()) {
    on<ProductListSubscriptionRequested>(_onSubscriptionRequested);
    on<_ProductsUpdated>(_onProductsUpdated);
    on<ProductDeleteRequested>(_onDeleteRequested);
  }
  Future<void> _onDeleteRequested(
    ProductDeleteRequested event,
    Emitter<ProductListState> emit,
  ) async {
    try {
      await _productRepository.deleteProduct(event.productId);
      // Opcional: podrías emitir un estado de éxito si quieres mostrar un SnackBar
    } catch (e) {
      // Opcional: podrías emitir un estado de error
      print('Error al eliminar desde el BLoC: $e');
    }
    // No necesitamos emitir un nuevo estado de la lista. Como estamos
    // escuchando en tiempo real, Firestore nos notificará del cambio
    // y el evento _ProductsUpdated actualizará la UI automáticamente.
  }

  void _onSubscriptionRequested(
    ProductListSubscriptionRequested event,
    Emitter<ProductListState> emit,
  ) {
    emit(state.copyWith(status: ProductListStatus.loading));
    _productsSubscription?.cancel();
    _productsSubscription = _productRepository.getAllProductsForAdmin().listen(
      (products) => add(_ProductsUpdated(products)),
      onError:
          (error) => emit(
            state.copyWith(
              status: ProductListStatus.failure,
              errorMessage: error.toString(),
            ),
          ),
    );
  }

  void _onProductsUpdated(
    _ProductsUpdated event,
    Emitter<ProductListState> emit,
  ) {
    emit(
      state.copyWith(
        status: ProductListStatus.success,
        products: event.products,
      ),
    );
  }

  @override
  Future<void> close() {
    _productsSubscription?.cancel();
    return super.close();
  }
}
