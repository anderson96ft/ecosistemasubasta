// lib/features/purchases/presentation/screens/purchases_screen.dart

import 'package:subasta/core/repositories/product_repository.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:subasta/features/home/presentation/widgets/product_card.dart';
import 'package:subasta/features/purchases/bloc/purchases_bloc.dart';
import 'package:subasta/features/purchases/bloc/purchases_event.dart';
import 'package:subasta/features/purchases/bloc/purchases_state.dart';
import 'package:subasta/presentation/widgets/info_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PurchasesBloc(
        productRepository: context.read<ProductRepository>(),
        authBloc: context.read<AuthBloc>(),
      )..add(PurchasesSubscriptionRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi Historial de Compras'),
        ),
        body: BlocBuilder<PurchasesBloc, PurchasesState>(
          builder: (context, state) {
            if (state.status == PurchasesStatus.loading || state.status == PurchasesStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == PurchasesStatus.failure) {
              return Center(child: Text('Error al cargar tu historial: ${state.errorMessage}'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<PurchasesBloc>().add(PurchasesSubscriptionRequested());
              },
              child: state.purchaseHistory.isEmpty
                  ? const Center(
                      child: InfoMessageWidget(
                        icon: Icons.receipt_long_outlined,
                        title: 'Sin Compras',
                        message: 'Tus compras y subastas ganadas aparecerán aquí.',
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: state.purchaseHistory.length,
                      itemBuilder: (context, index) {
                        return ProductCard(product: state.purchaseHistory[index]);
                      },
                    ),
            );
          },
        ),
      ),
    );
  }
}