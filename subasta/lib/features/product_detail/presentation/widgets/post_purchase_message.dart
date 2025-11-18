// lib/features/product_detail/presentation/widgets/post_purchase_message.dart

import 'package:subasta/features/nav/presentation/screens/nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:subasta/core/models/product_model.dart';

class PostPurchaseMessage extends StatelessWidget {
  final Product product;
  const PostPurchaseMessage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Aunque 'product' no se usa en el texto, ahora está disponible si lo necesitas.
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
          const SizedBox(height: 12),
          Text(
            '¡Felicidades! Has adquirido el ${product.model}.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Un administrador se pondrá en contacto contigo a través de la sección "Mensajes" para coordinar los siguientes pasos.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Ir a Mensajes'),
            onPressed: () {
              // Cierra la pantalla de detalle y navega a la pantalla principal,
              // seleccionando la pestaña de mensajes (índice 2).
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const NavScreen(initialIndex: 2)),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}