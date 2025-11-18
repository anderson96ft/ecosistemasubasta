// lib/features/product_detail/presentation/widgets/bid_modal_content.dart

import 'package:subasta/core/models/bid_model.dart';
import 'package:subasta/core/models/product_model.dart';
import 'package:subasta/features/product_detail/bloc/product_detail_bloc.dart';
import 'package:subasta/features/product_detail/bloc/product_detail_event.dart';
import 'package:subasta/features/product_detail/bloc/product_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BidModalContent extends StatefulWidget {
  // Recibimos los datos necesarios desde la pantalla principal
  final Product product;
  final List<Bid> bids;
  final String currentUserId;

  const BidModalContent({
    super.key,
    required this.product,
    required this.bids,
    required this.currentUserId,
  });

  @override
  State<BidModalContent> createState() => _BidModalContentState();
}

class _BidModalContentState extends State<BidModalContent> {
  final _bidController = TextEditingController();

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  /// Función auxiliar para enviar el evento de puja al BLoC.
  void _submitBid(double amount) {
    context.read<ProductDetailBloc>().add(BidSubmitted(amount));
  }

  @override
  Widget build(BuildContext context) {
    final currentPrice = widget.product.currentPrice ?? 0.0;

    // --- Lógica para calcular la posición y puja más alta del usuario ---
    final myBids =
        widget.bids.where((bid) => bid.userId == widget.currentUserId).toList();
    double? myHighestBidAmount;
    int myPosition = 0;
    bool isWinning = false;

    if (myBids.isNotEmpty) {
      myHighestBidAmount =
          myBids.first.amount; // La lista de pujas ya viene ordenada
      final uniqueBidders = <String, double>{};
      for (final bid in widget.bids) {
        if (!uniqueBidders.containsKey(bid.userId)) {
          uniqueBidders[bid.userId] = bid.amount;
        }
      }
      final sortedBidders =
          uniqueBidders.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      myPosition =
          sortedBidders.indexWhere(
            (entry) => entry.key == widget.currentUserId,
          ) +
          1;
      isWinning = myPosition == 1;
    }
    // --- Fin de la lógica de cálculo ---

    // --- Cálculo de los montos para los botones de puja rápida ---
    final quickBid1 = currentPrice + 1;
    final quickBid2 = currentPrice + 2;
    final quickBid3 = currentPrice + 5;

    // Usamos BlocConsumer para escuchar cambios (y cerrar el modal) y para construir la UI.
    return BlocConsumer<ProductDetailBloc, ProductDetailState>(
      listener: (context, state) {
        // Si la puja tiene éxito, cerramos este modal.
        // La pantalla de atrás (ProductDetailScreen) es la responsable de mostrar el SnackBar.
        if (state.bidStatus == BidStatus.success) {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        }
      },
      builder: (context, state) {
        final isLoading = state.bidStatus == BidStatus.loading;

        // Usamos SingleChildScrollView para evitar desbordamiento vertical con el teclado.
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Realiza tu oferta',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('La puja actual es de \$${currentPrice.toStringAsFixed(2)}'),
              const Divider(height: 24),

              // Widget de feedback contextual para el usuario
              if (myPosition > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isWinning
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isWinning
                        ? '¡Vas ganando! Tu puja es la más alta.'
                        : 'Estás en $myPositionº lugar. Tu puja más alta: \$${myHighestBidAmount!.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          isWinning
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                    ),
                  ),
                ),
              if (myPosition > 0) const SizedBox(height: 16),

              // Botones de puja rápida
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: isLoading ? null : () => _submitBid(quickBid1),
                    child: Text('\$${quickBid1.toStringAsFixed(2)}'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : () => _submitBid(quickBid2),
                    child: Text('\$${quickBid2.toStringAsFixed(2)}'),
                  ),
                  ElevatedButton(
                    onPressed: isLoading ? null : () => _submitBid(quickBid3),
                    child: Text('\$${quickBid3.toStringAsFixed(2)}'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Campo de texto para puja manual
              TextFormField(
                controller: _bidController,
                decoration: InputDecoration(
                  labelText: 'O introduce tu oferta máxima',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                enabled: !isLoading,
              ),
              const SizedBox(height: 24),

              // Botón de confirmación principal
              ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : () {
                          final amount = double.tryParse(_bidController.text);
                          if (amount != null && amount > 0) {
                            // --- LÓGICA DE CONFIRMACIÓN AÑADIDA ---
                            showDialog(
                              context: context,
                              builder:
                                  (dialogContext) => AlertDialog(
                                    title: const Text('Confirmar Puja'),
                                    content: Text(
                                      '¿Estás seguro de que quieres pujar \$${amount.toStringAsFixed(2)}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(
                                                  dialogContext,
                                                ).pop(),
                                        child: const Text('Cancelar'),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.of(
                                            dialogContext,
                                          ).pop(); // Cierra el diálogo
                                          _submitBid(amount); // Envía la puja
                                        },
                                        child: const Text('Confirmar'),
                                      ),
                                    ],
                                  ),
                            );
                          }
                        },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('REALIZAR PUJA'),
              ),
            ],
          ),
        );
      },
    );
  }
}
