// lib/features/home/presentation/screens/home_screen.dart

import 'package:subasta/core/repositories/product_repository.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:subasta/features/auth/bloc/auth_event.dart';
import 'package:subasta/features/home/presentation/widgets/product_card.dart';
import 'package:subasta/features/home/bloc/home_bloc.dart';
import 'package:subasta/features/home/bloc/home_event.dart';
import 'package:subasta/features/home/bloc/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

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
    // ignore: unused_local_variable
    final userEmail = context.select((AuthBloc bloc) => bloc.state.user.email);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos Disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Despachamos el evento para cerrar sesión desde el AuthBloc
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      floatingActionButton:
          kDebugMode // Solo muestra el botón en modo debug
              ? FloatingActionButton(
                child: const Icon(Icons.bug_report),
                tooltip: 'Panel de Depuración',
                onPressed: () {
                  _showDebugPanel(context);
                },
              )
              : null,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          // Usamos un switch para manejar limpiamente cada estado
          switch (state.status) {
            case HomeStatus.initial:
            case HomeStatus.loading:
              // Muestra un spinner mientras carga
              return const Center(child: CircularProgressIndicator());

            case HomeStatus.failure:
              // Muestra un mensaje de error si algo sale mal
              return Center(
                child: Text('Error al cargar productos: ${state.errorMessage}'),
              );

            case HomeStatus.success:
              // Si la carga fue exitosa, revisamos si la lista está vacía
              if (state.filteredProducts.isEmpty) {
                return const Center(
                  child: Text('No hay productos disponibles en este momento.'),
                );
              }
              // Si hay productos, los mostramos en una lista
              return ListView.builder(
                itemCount: state.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = state.filteredProducts[index];
                  // Aquí llamaremos a nuestro widget ProductCard (siguiente paso)
                  return ProductCard(product: product);
                },
              );
          }
        },
      ),
    );
  }

  // --- NUEVO MÉTODO PARA MOSTRAR EL MENÚ ---
  void _showDebugPanel(BuildContext context) {
    final productRepo = context.read<ProductRepository>();
    final userId = context.read<AuthBloc>().state.user.id;

    // Si el usuario no está logueado, no podemos simular escenarios de usuario
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para usar el panel de depuración.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Wrap(
          children: <Widget>[
            const ListTile(
              title: Text(
                'Simular Escenarios',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Estado Limpio (Productos Activos)'),
              onTap: () {
                productRepo.seedDatabase(
                  scenario: SeederScenario.clean,
                  currentUserId: userId,
                  otherUserId: 'otro_usuario_test',
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Voy Ganando una Subasta'),
              onTap: () {
                productRepo.seedDatabase(
                  scenario: SeederScenario.userIsWinning,
                  currentUserId: userId,
                  otherUserId: 'otro_usuario_test',
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_down),
              title: const Text('Voy Perdiendo una Subasta'),
              onTap: () {
                productRepo.seedDatabase(
                  scenario: SeederScenario.userIsLosing,
                  currentUserId: userId,
                  otherUserId: 'otro_usuario_test',
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('He Ganado una Subasta'),
              onTap: () {
                productRepo.seedDatabase(
                  scenario: SeederScenario.userHasWon,
                  currentUserId: userId,
                  otherUserId: 'otro_usuario_test',
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('He Comprado un Artículo'),
              onTap: () {
                productRepo.seedDatabase(
                  scenario: SeederScenario.userHasPurchased,
                  currentUserId: userId,
                  otherUserId: 'otro_usuario_test',
                );
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
