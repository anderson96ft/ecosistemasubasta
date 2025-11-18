// lib/core/models/product_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum SaleType { auction, directSale, unknown }

class Product extends Equatable {
  final String id;
  final String brand;
  final String model;
  final String condition;
  final String storage;
  final List<String> imageUrls;
  final SaleType saleType;

  // Campos para subasta
  final double? currentPrice;
  final Timestamp? endTime;

  // Campo para venta directa
  final double? fixedPrice;

  // ========================================================================
  // ===                  CAMPOS AÑADIDOS QUE FALTABAN                    ===
  // ========================================================================
  final String? status; // Puede ser 'active', 'finished', 'sold'
  final String? winnerId; // ID del ganador de la subasta
  final String? buyerId; // ID del comprador de venta directa
  final Timestamp? createdAt; // Fecha de creación del producto

  const Product({
    required this.id,
    required this.brand,
    required this.model,
    required this.condition,
    required this.storage,
    required this.imageUrls,
    required this.saleType,
    this.currentPrice,
    this.endTime,
    this.fixedPrice,
    // --- Añadidos al constructor ---
    this.status,
    this.winnerId,
    this.buyerId,
    this.createdAt,
  });

  factory Product.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;

    SaleType type;
    switch (data['saleType']) {
      case 'auction':
        type = SaleType.auction;
        break;
      case 'directSale':
        type = SaleType.directSale;
        break;
      default:
        type = SaleType.unknown;
    }

    final imageUrlsData = data['imageUrls'] as List<dynamic>?;
    final imageUrls =
        imageUrlsData?.map((url) => url.toString()).toList() ?? [];

    return Product(
      id: snap.id,
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      condition: data['condition'] ?? '',
      storage: data['storage'] ?? '',
      imageUrls: imageUrls,
      saleType: type,
      currentPrice: (data['currentPrice'] as num?)?.toDouble(),
      endTime: data['endTime'] as Timestamp?,
      fixedPrice: (data['fixedPrice'] as num?)?.toDouble(),
      // --- Leemos los nuevos campos desde Firestore ---
      status: data['status'] as String?,
      winnerId: data['winnerId'] as String?,
      buyerId: data['buyerId'] as String?,
      createdAt: data['createdAt'] as Timestamp?, // Leemos la fecha de creación
    );
  }

  @override
  List<Object?> get props => [
    id, brand, model, condition, storage, imageUrls,
    saleType, currentPrice, endTime, fixedPrice,
    // --- Añadidos a los props de Equatable ---
    status, winnerId, buyerId, createdAt,
  ];
}
