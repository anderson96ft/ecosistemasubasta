import 'package:admin_panel/core/models/product_model.dart';
import 'package:admin_panel/features/dashboard/presentation/screens/product_edit_screen.dart';
import 'package:flutter/material.dart';

/// Este fichero está obsoleto y se mantiene por compatibilidad temporal.
/// Redirige a la pantalla correcta: ProductEditScreen.
class AddEditProductScreen extends StatelessWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  Widget build(BuildContext context) {
    // Simplemente redirige a la pantalla correcta.
    return ProductEditScreen(product: product);
  }
}