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

  // Campos de estado y propietario
  final String? status;
  final String? winnerId;
  final String? buyerId;
  final String? highestBidderId; // <-- El campo que faltaba
  final String? sellerId; // <-- Campo útil para el futuro

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
    this.status,
    this.winnerId,
    this.buyerId,
    this.highestBidderId, // <-- Añadido al constructor
    this.sellerId, // <-- Añadido al constructor
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
      status: data['status'] as String?,
      winnerId: data['winnerId'] as String?,
      buyerId: data['buyerId'] as String?,
      highestBidderId:
          data['highestBidderId'] as String?, // <-- Leemos desde Firestore
      sellerId: data['sellerId'] as String?, // <-- Leemos desde Firestore
    );
  }

  @override
  List<Object?> get props => [
    id, brand, model, condition, storage, imageUrls,
    saleType, currentPrice, endTime, fixedPrice,
    status,
    winnerId,
    buyerId,
    highestBidderId,
    sellerId, // <-- Añadidos a los props
  ];
}
