// lib/features/dashboard/presentation/screens/auction_details_screen.dart

import 'package:admin_panel/core/models/product_model.dart';
import 'package:admin_panel/core/models/user_details_model.dart';
import 'package:admin_panel/core/repositories/auth_repository.dart';
import 'package:admin_panel/core/repositories/product_repository.dart';
import 'package:admin_panel/features/dashboard/bloc/auction_confirmation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AuctionDetailsScreen extends StatelessWidget {
  final Product product;

  const AuctionDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuctionConfirmationCubit(
        productRepository: context.read<ProductRepository>(),
        authRepository: context.read<AuthRepository>(),
        product: product,
      )..loadBidders(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Detalles de Subasta: ${product.model}'),
        ),
        body: BlocBuilder<AuctionConfirmationCubit, AuctionConfirmationState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(child: Text('Error: ${state.error}'));
            }
            if (state.bidders.isEmpty) {
              return const Center(
                child: Text(
                  'Aún no hay pujas para este producto.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              itemCount: state.bidders.length,
              itemBuilder: (dialogContext, index) {
                final bidderInfo = state.bidders[index];
                final isHighestBidder = index == 0;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: isHighestBidder ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isHighestBidder
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isHighestBidder
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      bidderInfo.userDetails.name ?? 'Usuario Anónimo',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Puja: \$${bidderInfo.bid.amount.toStringAsFixed(2)}\n'
                      'Fecha: ${DateFormat.yMd().add_jm().format(bidderInfo.bid.timestamp.toDate())}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    isThreeLine: true,
                    onTap: () {
                      _showUserDetailsDialog(
                        context, // Usar el contexto del diálogo
                        bidderInfo.userDetails.uid,
                        'Pujador',
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- NUEVO: Diálogo para mostrar detalles del usuario ---
void _showUserDetailsDialog(BuildContext context, String userId, String title) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      // Usamos un FutureBuilder para cargar los datos del usuario de forma asíncrona
      return FutureBuilder<UserDetails>(
        future: context.read<AuthRepository>().getUserDetails(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              title: Text('Cargando...'),
              content: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return AlertDialog(
              title: const Text('Error'),
              content:
                  const Text('No se pudieron cargar los detalles del usuario.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          }

          final user = snapshot.data!;
          return AlertDialog(
            title: Text('Detalles del $title'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(leading: const Icon(Icons.person), title: Text(user.name ?? 'Nombre no disponible')),
                ListTile(leading: const Icon(Icons.email), title: Text(user.email ?? 'Email no disponible')),
                ListTile(leading: const Icon(Icons.phone), title: Text(user.phone ?? 'Teléfono no disponible')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
            ],
          );
        },
      );
    },
  );
}
