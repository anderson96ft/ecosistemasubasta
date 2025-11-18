// lib/features/home/bloc/home_event.dart

import 'package:equatable/equatable.dart';
import 'package:subasta/core/models/product_model.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object> get props => [];
}

/// Evento que se dispara desde la UI para solicitar la carga
/// y suscripción a la lista de productos.
class HomeSubscriptionRequested extends HomeEvent {}

/// Evento interno que se dispara por el BLoC cuando el Stream
/// desde el repositorio emite una nueva lista de productos.
class HomeProductsUpdated extends HomeEvent {
  final List<Product> products;
  const HomeProductsUpdated(this.products);

  @override
  List<Object> get props => [products];
}

class HomeSearchTermChanged extends HomeEvent {
  final String searchTerm;
  const HomeSearchTermChanged(this.searchTerm);

  @override
  List<Object> get props => [searchTerm];
}
