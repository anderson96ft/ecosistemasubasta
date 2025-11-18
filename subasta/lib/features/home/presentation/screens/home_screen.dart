// lib/features/home/presentation/screens/home_screen.dart

import 'package:subasta/core/repositories/product_repository.dart';
import 'package:subasta/features/home/presentation/widgets/product_card.dart';
import 'package:subasta/features/home/bloc/home_bloc.dart';
import 'package:subasta/features/home/bloc/home_event.dart';
import 'package:subasta/features/home/bloc/home_state.dart';
import 'package:subasta/presentation/widgets/info_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- Widget Principal: Provee el BLoC ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => HomeBloc(
              // Obtenemos el repositorio que proveímos en main.dart
              productRepository: context.read<ProductRepository>(),
            )
            // Despachamos el evento para empezar a cargar los datos tan pronto
            // como el BLoC es creado.
            ..add(HomeSubscriptionRequested()),
      child: const HomeView(),
    );
  }
}

// --- La Vista: Construye la UI según el estado ---

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Convertimos el título en un campo de texto para la búsqueda
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            onChanged: (value) {
              // Cada vez que el usuario escribe, enviamos un evento al BLoC
              context.read<HomeBloc>().add(HomeSearchTermChanged(value));
            },
            decoration: InputDecoration(
              hintText: 'Buscar por marca o modelo...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          switch (state.status) {
            case HomeStatus.initial:
            case HomeStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case HomeStatus.failure:
            // ...
            case HomeStatus.success:
              // --- CAMBIO: Usamos 'filteredProducts' en lugar de 'products' ---
              if (state.filteredProducts.isEmpty) {
                // Mostramos un mensaje diferente si la lista está vacía por un filtro
                if (state.searchTerm.isNotEmpty) {
                  return const InfoMessageWidget(
                    icon: Icons.search_off,
                    title: 'Sin resultados',
                    message:
                        'No se encontraron productos que coincidan con tu búsqueda.',
                  );
                }
                return const InfoMessageWidget(
                  icon: Icons.storefront_outlined,
                  title: 'No hay productos',
                  message: 'Parece que no hay nada disponible en este momento.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeBloc>().add(HomeSubscriptionRequested());
                },
                // --- CAMBIO: Usamos 'filteredProducts' para construir la lista ---
                child: ListView.builder(
                  itemCount: state.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = state.filteredProducts[index];
                    return ProductCard(product: product);
                  },
                ),
              );
          }
        },
      ),
    );
  }
}
