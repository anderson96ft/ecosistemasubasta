// lib/features/bids/presentation/screens/bids_screen.dart

import 'package:subasta/core/repositories/product_repository.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:subasta/features/bids/bloc/bids_bloc.dart';
import 'package:subasta/features/bids/bloc/bids_event.dart';
import 'package:subasta/features/bids/bloc/bids_state.dart';
import 'package:subasta/features/home/presentation/widgets/product_card.dart';
import 'package:subasta/presentation/widgets/info_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BidsScreen extends StatelessWidget {
  const BidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BidsBloc(
        productRepository: context.read<ProductRepository>(),
        authBloc: context.read<AuthBloc>(),
      )..add(BidsSubscriptionRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Pujas'),
        ),
        body: BlocBuilder<BidsBloc, BidsState>(
          builder: (context, state) {
            if (state.status == BidsStatus.loading || state.status == BidsStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == BidsStatus.failure) {
              return Center(child: Text('Error al cargar tus pujas: ${state.errorMessage}'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<BidsBloc>().add(BidsSubscriptionRequested());
              },
              child: ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  // --- Sección de Pujas Activas ---
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Pujas Activas', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  if (state.activeBids.isEmpty)
                    const InfoMessageWidget(
                      icon: Icons.gavel_rounded,
                      title: 'Sin Pujas Activas',
                      message: 'Aquí aparecerán las subastas donde vayas ganando.',
                    )
                  else
                    ...state.activeBids.map((product) => ProductCard(product: product)),
                  
                  const Divider(height: 32),

                  // --- Sección de Subastas en Confirmación ---
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('En Confirmación', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  if (state.pendingAuctions.isEmpty)
                    const InfoMessageWidget(
                      icon: Icons.hourglass_top_outlined,
                      title: 'Ninguna Subasta Pendiente',
                      message: 'Las subastas en las que participaste y que están finalizando aparecerán aquí.',
                    )
                  else
                    ...state.pendingAuctions.map((product) => ProductCard(product: product)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}