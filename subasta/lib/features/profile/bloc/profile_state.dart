// lib/features/profile/bloc/profile_state.dart

import 'package:equatable/equatable.dart';
import 'package:subasta/core/models/product_model.dart';
import 'package:subasta/features/profile/bloc/profile_event.dart'; // Importa el enum SortOption

enum ProfileStatus { initial, loading, success, failure }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final List<Product> activeBids;
  final List<Product> wonAuctions; // Lista separada para subastas ganadas
  final List<Product> directPurchases; // Lista separada para compras directas
  final List<Product> pendingAuctions;
  final String errorMessage;
  final SortOption sortOption; // Opción de ordenación actual

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.activeBids = const [],
    this.wonAuctions = const [],
    this.directPurchases = const [],
    this.pendingAuctions = const [],
    this.errorMessage = '',
    this.sortOption = SortOption.date,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    List<Product>? activeBids,
    List<Product>? wonAuctions,
    List<Product>? directPurchases,
    List<Product>? pendingAuctions,
    String? errorMessage,
    SortOption? sortOption,
  }) {
    return ProfileState(
      status: status ?? this.status,
      activeBids: activeBids ?? this.activeBids,
      wonAuctions: wonAuctions ?? this.wonAuctions,
      directPurchases: directPurchases ?? this.directPurchases,
      pendingAuctions: pendingAuctions ?? this.pendingAuctions,
      errorMessage: errorMessage ?? this.errorMessage,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeBids,
        wonAuctions,
        directPurchases,
        pendingAuctions,
        errorMessage,
        sortOption,
      ];
}
