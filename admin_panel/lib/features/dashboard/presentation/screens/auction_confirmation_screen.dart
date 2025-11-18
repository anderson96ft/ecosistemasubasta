// lib/features/dashboard/presentation/screens/auction_confirmation_screen.dart

import 'package:admin_panel/core/models/product_model.dart';
import 'package:admin_panel/core/repositories/auth_repository.dart';
import 'package:admin_panel/core/repositories/product_repository.dart';
// --- 1. IMPORTA EL AUTH_BLOC ---
// (Necesario para obtener el ID del administrador que está logueado)
import 'package:admin_panel/features/auth/bloc/auth_bloc.dart';
import 'package:admin_panel/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:admin_panel/features/dashboard/bloc/auction_confirmation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuctionConfirmationScreen extends StatelessWidget {
  final Product product;

  const AuctionConfirmationScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => AuctionConfirmationCubit(
            productRepository: context.read<ProductRepository>(),
            authRepository: context.read<AuthRepository>(),
            product: product,
          )..loadBidders(),
      child: AuctionConfirmationView(product: product),
    );
  }
}

class AuctionConfirmationView extends StatelessWidget {
  final Product product;
  const AuctionConfirmationView({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // --- 2. OBTÉN EL ID DEL ADMIN ACTUAL ---
    final adminId = context.read<AuthBloc>().state.user.id;

    return Scaffold(
      appBar: AppBar(title: Text('Confirmar: ${product.model}')),
      body: BlocConsumer<AuctionConfirmationCubit, AuctionConfirmationState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          // Si la venta se confirma, cierra esta pantalla
          if (state.isLoading == false && product.status == 'sold') {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.bidders.isEmpty) {
            return const Center(
              child: Text('Esta subasta no recibió ninguna puja.'),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lista de Pujadores',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Contacta a los pujadores en orden descendente para confirmar la venta.',
                    ),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Pos.')),
                          DataColumn(label: Text('Monto')),
                          DataColumn(label: Text('Pujador (Email)')),
                          DataColumn(label: Text('Teléfono')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: List.generate(state.bidders.length, (index) {
                          final bidderInfo = state.bidders[index];
                          final isTopBidder = index == 0;

                          return DataRow(
                            color:
                                isTopBidder
                                    ? WidgetStateProperty.all(
                                      Colors.green.withOpacity(0.1),
                                    )
                                    : null,
                            cells: [
                              DataCell(Text('${index + 1}º')),
                              DataCell(
                                Text(
                                  '\$${bidderInfo.bid.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    Text(bidderInfo.userDetails.email),
                                    if (bidderInfo.hasIncidents) ...[
                                      const SizedBox(width: 8),
                                      const Tooltip(
                                        message:
                                            'Este usuario tiene incidentes previos.',
                                        child: Icon(
                                          Icons.flag,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              DataCell(Text(bidderInfo.userDetails.phone)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chat_outlined),
                                      color: Theme.of(context).primaryColor,
                                      tooltip: 'Contactar a este pujador',
                                      onPressed: () {
                                        // --- 3. LÓGICA DE ID UNIFICADA ---
                                        // Se ordena alfabéticamente para que el ID sea
                                        // consistente entre el admin y el usuario.
                                        final participants = [
                                          adminId,
                                          bidderInfo.userDetails.uid,
                                        ]..sort();
                                        final conversationId = participants
                                            .join('_');
                                        // ---------------------------------

                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ChatDetailScreen(
                                                  conversationId:
                                                      conversationId, // <-- ID Unificado
                                                  otherUserId:
                                                      bidderInfo
                                                          .userDetails
                                                          .uid,
                                                  // Seguimos pasando el contexto del producto
                                                  productId: product.id,
                                                  productModel: product.model,
                                                  productImage:
                                                      product
                                                              .imageUrls
                                                              .isNotEmpty
                                                          ? product.imageUrls[0]
                                                          : null,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),

                                    // Muestra botones solo para el primer pujador
                                    if (isTopBidder) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                        ),
                                        color: Colors.green,
                                        tooltip: 'Confirmar Venta',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (dialogCtx) => AlertDialog(
                                                  title: const Text(
                                                    'Confirmar Venta',
                                                  ),
                                                  content: Text(
                                                    '¿Confirmar venta a ${bidderInfo.userDetails.email} por \$${bidderInfo.bid.amount.toStringAsFixed(2)}? Esta acción cerrará el chat y marcará el producto como "Vendido".',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () =>
                                                              Navigator.of(
                                                                dialogCtx,
                                                              ).pop(),
                                                      child: const Text(
                                                        'Cancelar',
                                                      ),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () {
                                                        Navigator.of(
                                                          dialogCtx,
                                                        ).pop(); // Cierra diálogo
                                                        context
                                                            .read<
                                                              AuctionConfirmationCubit
                                                            >()
                                                            .confirmSale()
                                                            .then((_) {
                                                              Navigator.of(
                                                                context,
                                                              ).pop(); // Cierra esta pantalla
                                                            });
                                                      },
                                                      style:
                                                          FilledButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.green,
                                                          ),
                                                      child: const Text(
                                                        'Confirmar',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined),
                                        color: Colors.red,
                                        tooltip:
                                            'Anular esta puja (Reportar y promover al siguiente)',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (dialogCtx) => AlertDialog(
                                                  title: const Text(
                                                    'Anular Puja',
                                                  ),
                                                  content: Text(
                                                    '¿Anular la puja de ${bidderInfo.userDetails.email}? Esto reportará un incidente, cerrará su chat y promoverá al siguiente pujador.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () =>
                                                              Navigator.of(
                                                                dialogCtx,
                                                              ).pop(),
                                                      child: const Text(
                                                        'Cancelar',
                                                      ),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () {
                                                        Navigator.of(
                                                          dialogCtx,
                                                        ).pop(); // Cierra diálogo
                                                        context
                                                            .read<
                                                              AuctionConfirmationCubit
                                                            >()
                                                            .reportAndAnnulBid(
                                                              bidderInfo,
                                                            );
                                                        // No cerramos, el cubit recargará
                                                      },
                                                      style:
                                                          FilledButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                      child: const Text(
                                                        'Anular Puja',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
