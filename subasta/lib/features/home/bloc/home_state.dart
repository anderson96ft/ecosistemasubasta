// lib/features/home/bloc/home_state.dart
import 'package:equatable/equatable.dart';
import 'package:subasta/core/models/product_model.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  // --- NUEVAS PROPIEDADES ---
  final String searchTerm;          // Para guardar lo que el usuario escribe
  final List<Product> allProducts;  // La lista original, sin filtrar
  final List<Product> filteredProducts; // La lista que realmente mostramos

  final String errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.searchTerm = '',
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.errorMessage = '',
  });

  HomeState copyWith({
    HomeStatus? status,
    String? searchTerm,
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      searchTerm: searchTerm ?? this.searchTerm,
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object> get props => [status, searchTerm, allProducts, filteredProducts, errorMessage];
}