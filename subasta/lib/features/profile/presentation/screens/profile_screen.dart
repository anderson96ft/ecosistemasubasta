// lib/features/profile/presentation/screens/profile_screen.dart
import 'package:subasta/core/models/product_model.dart';
import 'package:subasta/features/auth/bloc/auth_event.dart';
import 'package:subasta/features/product_detail/presentation/screens/product_detail_screen.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:subasta/features/profile/bloc/profile_event.dart';
import 'package:subasta/features/profile/bloc/profile_state.dart';
import 'package:subasta/features/profile/bloc/profile_bloc.dart';
import 'package:subasta/presentation/widgets/info_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(
        productRepository: context.read(),
        authBloc: context.read(),
      )..add(ProfileSubscriptionRequested()),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos DefaultTabController para manejar el estado de las pestañas
    return DefaultTabController(
      length: 3, // 3 pestañas: Activas, Ganadas, Compradas
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi Actividad'),
          actions: [
            // Botón para resincronizar notificaciones
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sincronizar Notificaciones',
              onPressed: () => context.read<AuthBloc>().add(const RegisterFCMToken()),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar Sesión',
              onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'EN CURSO'),
              Tab(text: 'GANADAS'),
              Tab(text: 'COMPRADAS'),
            ],
          ),
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state.status == ProfileStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == ProfileStatus.failure) {
              return Center(child: Text('Error: ${state.errorMessage}'));
            }

            // Contenido para cada pestaña
            return TabBarView(
              children: [
                // Pestaña 1: En Curso (Pujas activas y pendientes)
                _buildInProgresList(context, state.activeBids, state.pendingAuctions),
                
                // Pestaña 2: Subastas Ganadas
                _buildHistoryList(
                  context: context,
                  products: state.wonAuctions,
                  sortOption: state.sortOption,
                  emptyTitle: 'Sin subastas ganadas',
                  emptyMessage: 'Cuando ganes una subasta, aparecerá aquí.',
                ),

                // Pestaña 3: Compras Directas
                _buildHistoryList(
                  context: context,
                  products: state.directPurchases,
                  sortOption: state.sortOption,
                  emptyTitle: 'Sin compras directas',
                  emptyMessage: 'Los artículos que compres directamente se mostrarán aquí.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget para la pestaña "En Curso"
  Widget _buildInProgresList(BuildContext context, List<Product> activeBids, List<Product> pendingAuctions) {
    if (activeBids.isEmpty && pendingAuctions.isEmpty) {
      return const InfoMessageWidget(
        icon: Icons.gavel_outlined,
        title: 'Todo tranquilo por aquí',
        message: 'Tus pujas activas y subastas pendientes de confirmación aparecerán aquí.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        if (activeBids.isNotEmpty) ...[
          _SectionHeader(title: 'Pujas Activas (${activeBids.length})'),
          ...activeBids.map((product) => _ProductListItem(product: product)),
          const Divider(height: 32),
        ],
        if (pendingAuctions.isNotEmpty) ...[
          _SectionHeader(title: 'Pendientes de Confirmación (${pendingAuctions.length})'),
          ...pendingAuctions.map((product) => _ProductListItem(product: product)),
        ],
      ],
    );
  }

  // Widget genérico para las pestañas de historial (Ganadas y Compradas)
  Widget _buildHistoryList({
    required BuildContext context,
    required List<Product> products,
    required SortOption sortOption,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    if (products.isEmpty) {
      return InfoMessageWidget(icon: Icons.history, title: emptyTitle, message: emptyMessage);
    }
    return Column(
      children: [
        _SortControls(
          currentSortOption: sortOption,
          onSortChanged: (newOption) {
            if (newOption != null) {
              context.read<ProfileBloc>().add(SortHistoryRequested(newOption));
            }
          },
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: products.length,
            itemBuilder: (context, index) => _ProductListItem(product: products[index]),
          ),
        ),
      ],
    );
  }
}

// --- Widgets Auxiliares ---

class _SortControls extends StatelessWidget {
  final SortOption currentSortOption;
  final ValueChanged<SortOption?> onSortChanged;

  const _SortControls({required this.currentSortOption, required this.onSortChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text('Ordenar por:'),
          const SizedBox(width: 8),
          DropdownButton<SortOption>(
            value: currentSortOption,
            items: const [
              DropdownMenuItem(value: SortOption.date, child: Text('Fecha')),
              DropdownMenuItem(value: SortOption.name, child: Text('Nombre')),
              DropdownMenuItem(value: SortOption.price, child: Text('Precio')),
            ],
            onChanged: onSortChanged,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final Product product;
  const _ProductListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    final priceText = product.saleType == SaleType.auction
        ? 'Ganaste por: \$${product.currentPrice?.toStringAsFixed(2)}'
        : 'Comprado por: \$${product.fixedPrice?.toStringAsFixed(2)}';
    
    final date = product.endTime ?? product.createdAt;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: product.imageUrls.isNotEmpty ? NetworkImage(product.imageUrls.first) : null,
          child: product.imageUrls.isEmpty ? const Icon(Icons.image_not_supported) : null,
        ),
        title: Text(product.model),
        subtitle: Text(priceText),
        trailing: date != null ? Text(DateFormat.yMd().format(date.toDate())) : null,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id),
          ));
        },
      ),
    );
  }
}
