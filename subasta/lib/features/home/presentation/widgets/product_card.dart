// lib/features/home/presentation/widgets/product_card.dart

import 'package:subasta/core/models/product_model.dart';
import 'package:subasta/features/product_detail/presentation/screens/product_detail_screen.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        print('Navegando a detalles del producto con ID: ${product.id}');

        // Lógica de navegación
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        clipBehavior: Clip.antiAlias, // Para redondear la imagen
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGEN ---
            SizedBox(
              height: 200,
              width: double.infinity,
              child:
                  product.imageUrls.isNotEmpty
                      ? Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.cover,
                        // Placeholder mientras carga la imagen
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        // Widget a mostrar si hay un error al cargar la imagen
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.phone_android,
                            size: 100,
                            color: Colors.grey,
                          );
                        },
                      )
                      : const Icon(
                        Icons.phone_android,
                        size: 100,
                        color: Colors.grey,
                      ),
            ),

            // --- INFORMACIÓN ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.brand} ${product.model}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.condition} - ${product.storage}',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const Divider(height: 24),

                  // --- LÓGICA CONDICIONAL: SUBASTA O VENTA ---
                  if (product.saleType == SaleType.auction)
                    _AuctionInfo(
                      price: product.currentPrice ?? 0.0,
                      endTime:
                          product.endTime!
                              .toDate(), // Convertimos Timestamp a DateTime
                    )
                  else if (product.saleType == SaleType.directSale)
                    _DirectSaleInfo(price: product.fixedPrice ?? 0.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Widget Privado para Información de Subasta ---
class _AuctionInfo extends StatelessWidget {
  final double price;
  final DateTime endTime;

  const _AuctionInfo({required this.price, required this.endTime});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUBASTA',
          style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Puja actual: ',
            style: const TextStyle(fontSize: 16),
            children: [
              TextSpan(
                text: '\$${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Termina en: ${endTime.day}/${endTime.month}/${endTime.year} a las ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
        ),
      ],
    );
  }
}

// --- Widget Privado para Información de Venta Directa ---
class _DirectSaleInfo extends StatelessWidget {
  final double price;

  const _DirectSaleInfo({required this.price});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VENTA DIRECTA',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Precio: ',
            style: const TextStyle(fontSize: 16),
            children: [
              TextSpan(
                text: '\$${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
