// lib/features/home/bloc/home_bloc.dart

import 'dart:async';
import 'package:subasta/core/models/product_model.dart';
import 'package:subasta/core/repositories/product_repository.dart';
import 'package:bloc/bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ProductRepository _productRepository;
  StreamSubscription? _productsSubscription;

  HomeBloc({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(const HomeState()) {
    on<HomeSubscriptionRequested>(_onSubscriptionRequested);
    on<HomeProductsUpdated>(_onProductsUpdated);
    // 1. Registramos el manejador para el nuevo evento de búsqueda
    on<HomeSearchTermChanged>(_onSearchTermChanged);
  }

  void _onSubscriptionRequested(
    HomeSubscriptionRequested event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(status: HomeStatus.loading));
    _productsSubscription?.cancel();
    _productsSubscription = _productRepository.getAvailableProducts().listen(
      (products) => add(HomeProductsUpdated(products)),
      onError: (error) => emit(state.copyWith(status: HomeStatus.failure, errorMessage: error.toString())),
    );
  }
  
  // --- MÉTODO MODIFICADO ---
  void _onProductsUpdated(HomeProductsUpdated event, Emitter<HomeState> emit) {
    // Cuando llegan nuevos productos, los guardamos en 'allProducts'
    // y aplicamos el filtro actual inmediatamente.
    emit(state.copyWith(
      status: HomeStatus.success,
      allProducts: event.products,
      filteredProducts: _filterProducts(event.products, state.searchTerm), // Aplicamos filtro
    ));
  }

  // --- NUEVO MÉTODO ---
  void _onSearchTermChanged(HomeSearchTermChanged event, Emitter<HomeState> emit) {
    // Cuando el término de búsqueda cambia, actualizamos el estado
    // y volvemos a filtrar la lista 'allProducts' que ya teníamos.
    final searchTerm = event.searchTerm;
    emit(state.copyWith(
      searchTerm: searchTerm,
      filteredProducts: _filterProducts(state.allProducts, searchTerm),
    ));
  }
  
  // --- NUEVA FUNCIÓN AUXILIAR DE FILTRADO ---
  List<Product> _filterProducts(List<Product> allProducts, String searchTerm) {
    if (searchTerm.isEmpty) {
      // Si la búsqueda está vacía, mostramos todos los productos.
      return allProducts;
    } else {
      // Si no, filtramos la lista.
      return allProducts.where((product) {
        // Creamos un string de búsqueda combinando marca y modelo.
        final searchableString = '${product.brand} ${product.model}'.toLowerCase();
        // Comprobamos si el string contiene el término de búsqueda.
        return searchableString.contains(searchTerm.toLowerCase());
      }).toList();
    }
  }

  @override
  Future<void> close() {
    _productsSubscription?.cancel();
    return super.close();
  }
}