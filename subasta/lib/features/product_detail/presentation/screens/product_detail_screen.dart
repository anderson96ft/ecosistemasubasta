// lib/features/product_detail/presentation/screens/product_detail_screen.dart

import 'dart:async'; // Necesario para Timer
import 'package:subasta/core/models/bid_model.dart';
import 'package:subasta/core/models/product_model.dart';
import 'package:subasta/core/repositories/product_repository.dart';
import 'package:subasta/features/auth/bloc/auth_bloc.dart';
import 'package:subasta/features/auth/bloc/auth_state.dart';
import 'package:subasta/features/auth/presentation/screens/login_screen.dart'; // <-- IMPORT CAMBIADO
import 'package:subasta/features/product_detail/bloc/product_detail_bloc.dart';
import 'package:subasta/features/product_detail/bloc/product_detail_event.dart';
import 'package:subasta/features/product_detail/bloc/product_detail_state.dart';
import 'package:subasta/features/product_detail/presentation/widgets/bid_modal_content.dart';
import 'package:subasta/features/product_detail/presentation/widgets/post_purchase_message.dart';
import 'package:subasta/presentation/widgets/info_message_widget.dart'; // Import del widget genérico
import 'package:cloud_firestore/cloud_firestore.dart'; // Necesario para Timestamp
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart'; // Comentado si no se usa DateFormat

// --- Widget Principal y Proveedor del BLoC ---
class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => ProductDetailBloc(
            productRepository: context.read<ProductRepository>(),
            authBloc: context.read<AuthBloc>(), // Se pasa el AuthBloc completo
          )..add(
            ProductDetailSubscriptionRequested(productId),
          ), // Dispara el evento inicial
      child: const ProductDetailView(),
    );
  }
}

// --- La Vista Principal (Scaffold y BlocBuilder) ---
class ProductDetailView extends StatelessWidget {
  const ProductDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha el producto actual para mostrarlo en el AppBar incluso mientras carga
    final product = context.select(
      (ProductDetailBloc bloc) => bloc.state.product,
    );

    return Scaffold(
      appBar: AppBar(title: Text(product?.model ?? 'Detalles del Producto')),
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          switch (state.status) {
            case ProductDetailStatus.initial:
            case ProductDetailStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case ProductDetailStatus.failure:
              return Center(
                child: Text('Error al cargar detalles: ${state.errorMessage}'),
              );
            case ProductDetailStatus.success:
              if (state.product == null) {
                return const Center(child: Text('Producto no encontrado.'));
              }
              // Si todo está bien, muestra el contenido del producto
              return _ProductContent(product: state.product!);
          }
        },
      ),
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  final List<String> imageUrls;
  const _ImageCarousel({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.phone_android, size: 100, color: Colors.grey),
        ),
      );
    }

    final pageController = PageController();
    final currentPageNotifier = ValueNotifier<int>(0);

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: pageController,
            itemCount: imageUrls.length,
            onPageChanged: (value) => currentPageNotifier.value = value,
            itemBuilder: (context, index) => Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
          ),
        ),
        if (imageUrls.length > 1)
          ValueListenableBuilder<int>(
            valueListenable: currentPageNotifier,
            builder: (context, currentPage, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  imageUrls.length,
                  (index) => Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 2.0,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentPage == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// --- Widget de Información de Cabecera ---
class _HeaderInfo extends StatelessWidget {
  final Product product;
  const _HeaderInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${product.brand} ${product.model}',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Chip(
          label: Text('${product.condition} - ${product.storage}'),
          backgroundColor: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        // Aquí podrías añadir más detalles si los tienes en el modelo Product
      ],
    );
  }
}

// --- Widget de Contenido Principal ---
class _ProductContent extends StatelessWidget {
  final Product product;
  const _ProductContent({required this.product});

  @override
  Widget build(BuildContext context) {
    // 1. La lógica para determinar si el usuario es dueño ahora está en el estado del BLoC.
    //    Usamos `context.select` para reconstruir este widget solo si `isCurrentUserOwner` cambia.
    final isOwner = context.select((ProductDetailBloc bloc) => bloc.state.isCurrentUserOwner);

    // 2. Si el usuario es el dueño, muestra el mensaje post-compra.
    if (isOwner) {
      return PostPurchaseMessage(product: product);
    }

    // 4. Si no es el dueño, muestra la vista de detalle normal.
    return ListView(
      children: [
        _ImageCarousel(imageUrls: product.imageUrls),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderInfo(product: product), // Muestra el nombre y la condición
              const SizedBox(height: 24),
              // Muestra el área de acción correcta según el tipo de venta
              if (product.saleType == SaleType.auction) // <-- CORRECCIÓN
                _AuctionActionArea(product: product)
              else
                _DirectSaleActionArea(product: product),
            ],
          ),
        ),
      ],
    );
  }
}

// --- Widget de Acción para SUBASTA ---
class _AuctionActionArea extends StatelessWidget {
  final Product product;
  const _AuctionActionArea({required this.product});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final state = context.watch<ProductDetailBloc>().state;
    final authState = context.watch<AuthBloc>().state;
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final currentUserId = authState.user.id;

    // Escucha los cambios en bidStatus para mostrar Snackbars
    return BlocListener<ProductDetailBloc, ProductDetailState>(
      listenWhen:
          (previous, current) => previous.bidStatus != current.bidStatus,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).hideCurrentSnackBar(); // Oculta SnackBar anterior
        if (state.bidStatus == BidStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Puja realizada con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.bidStatus == BidStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.bidErrorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SUBASTA',
            style: textTheme.titleMedium?.copyWith(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text('Puja actual:', style: textTheme.titleMedium),
          Text(
            '\$${product.currentPrice?.toStringAsFixed(2) ?? '0.00'}',
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _TimeRemaining(endTime: product.endTime), // Widget del contador
          // Muestra el estado de la puja del usuario si está autenticado y hay pujas
          if (isAuthenticated && state.bids.isNotEmpty) ...[
            const SizedBox(height: 16),
            _BidStatusInfo(bids: state.bids, currentUserId: currentUserId),
          ],

          const SizedBox(height: 24),

          // Muestra botón de Ofertar o mensaje según el estado del producto
          if (product.status == 'active')
            ElevatedButton(
              onPressed: () {
                if (isAuthenticated) {
                  // Abre el modal para pujar
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled:
                        true, // Permite que el modal sea más alto
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) {
                      // Provee el BLoC al modal
                      return BlocProvider.value(
                        value: context.read<ProductDetailBloc>(),
                        child: BidModalContent(
                          product: product,
                          bids: state.bids,
                          currentUserId: currentUserId,
                        ),
                      );
                    },
                  );
                } else {
                  // --- CAMBIO AQUÍ: Navega a LoginScreen ---
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  // ----------------------------------------
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isAuthenticated ? 'OFERTAR' : 'INICIAR SESIÓN PARA OFERTAR',
              ),
            )
          else if (product.status == 'pending_confirmation')
            const InfoMessageWidget(
              // Usa el widget genérico
              icon: Icons.hourglass_top_outlined,
              title: 'Subasta Finalizada',
              message:
                  'Esperando confirmación del ganador. Aún tienes una oportunidad si eres el siguiente en la lista.',
            )
          else // Podrías añadir casos para 'sold', 'cancelled', etc.
            const InfoMessageWidget(
              icon: Icons.check_circle_outline,
              title: 'Subasta Concluida',
              message: 'Esta subasta ya ha finalizado.',
            ),
        ],
      ),
    );
  }
}

// --- Widget auxiliar para el contador de tiempo ---
class _TimeRemaining extends StatefulWidget {
  final Timestamp? endTime;
  const _TimeRemaining({this.endTime});

  @override
  State<_TimeRemaining> createState() => _TimeRemainingState();
}

class _TimeRemainingState extends State<_TimeRemaining> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancela timer anterior si existe
    if (widget.endTime != null) {
      _updateRemainingTime(); // Calcula el tiempo inicial
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        _updateRemainingTime();
      });
    }
  }

  void _updateRemainingTime() {
    if (widget.endTime == null) return;
    final now = DateTime.now();
    final end = widget.endTime!.toDate();
    final remaining = end.difference(now);
    setState(() {
      _timeRemaining = remaining;
      if (remaining.isNegative && (_timer?.isActive ?? false)) {
        _timer?.cancel();
      }
    });
  }

  // Actualiza el timer si cambia el endTime del producto (raro, pero posible)
  @override
  void didUpdateWidget(covariant _TimeRemaining oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.endTime != oldWidget.endTime) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "Finalizada";
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    // Formato más compacto
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tiempo restante:', style: textTheme.titleMedium),
        Text(
          _formatDuration(_timeRemaining),
          style: textTheme.headlineSmall?.copyWith(
            color:
                _timeRemaining.isNegative
                    ? Colors.redAccent
                    : Colors.blueAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// --- Widget de Estado de Puja ---
class _BidStatusInfo extends StatelessWidget {
  final List<Bid> bids;
  final String currentUserId;

  const _BidStatusInfo({required this.bids, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    // No muestra nada si el usuario no está logueado o no hay pujas
    if (currentUserId.isEmpty || bids.isEmpty) return const SizedBox.shrink();

    // Encuentra la puja más alta del usuario actual
    final myBids = bids.where((bid) => bid.userId == currentUserId).toList();
    if (myBids.isEmpty) {
      // Si el usuario ha pujado antes pero ya no está en la lista (raro), no muestra nada
      return const SizedBox.shrink();
    }
    // La lista 'bids' viene ordenada DESC por amount desde el BLoC
    final myHighestBidAmount = myBids.first.amount;

    // Encuentra la posición del usuario entre los pujadores únicos
    final uniqueBidders = <String, double>{};
    for (final bid in bids) {
      // Guarda la puja más alta de cada usuario
      if (!uniqueBidders.containsKey(bid.userId) ||
          bid.amount > uniqueBidders[bid.userId]!) {
        uniqueBidders[bid.userId] = bid.amount;
      }
    }
    // Ordena los pujadores únicos por monto de puja (descendente)
    final sortedBidders =
        uniqueBidders.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Calcula la posición (+1 porque el índice es base 0)
    final myPosition =
        sortedBidders.indexWhere((entry) => entry.key == currentUserId) + 1;
    final isWinning = myPosition == 1;

    // Devuelve el widget con la información de estado
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinning ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinning ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWinning ? Icons.check_circle_outline : Icons.info_outline,
            color: isWinning ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWinning
                      ? '¡Vas ganando!'
                      : (myPosition > 0
                          ? 'Tu posición: ${myPosition}º lugar'
                          : 'Has pujado'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isWinning
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                  ),
                ),
                Text(
                  'Tu puja más alta: \$${myHighestBidAmount.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Widget de Acción para VENTA DIRECTA ---
class _DirectSaleActionArea extends StatelessWidget {
  final Product product;
  const _DirectSaleActionArea({required this.product});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Escucha el estado de la acción (compra)
    final actionStatus = context.select(
      (ProductDetailBloc bloc) => bloc.state.bidStatus,
    );
    final isAuthenticated = context.select(
      (AuthBloc bloc) => bloc.state.status == AuthStatus.authenticated,
    );

    // Escucha cambios en el estado para mostrar Snackbars o navegar
    return BlocListener<ProductDetailBloc, ProductDetailState>(
      listenWhen:
          (previous, current) => previous.bidStatus != current.bidStatus,
      listener: (context, state) {
        if (state.bidStatus == BidStatus.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('¡Gracias por tu compra!'),
                backgroundColor: Colors.green,
              ),
            );
          // YA NO NAVEGAMOS HACIA ATRÁS. La UI se reconstruirá automáticamente
          // para mostrar el mensaje de PostPurchaseMessage.
        } else if (state.bidStatus == BidStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Error: ${state.bidErrorMessage}'),
                backgroundColor: Colors.red,
              ),
            );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VENTA DIRECTA',
            style: textTheme.titleMedium?.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text('Precio fijo:', style: textTheme.titleMedium),
          Text(
            '\$${product.fixedPrice?.toStringAsFixed(2) ?? '0.00'}',
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Muestra botón de Comprar o mensaje según estado del producto
          if (product.status == 'active')
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    actionStatus ==
                            BidStatus
                                .loading // Deshabilita si está cargando
                        ? null
                        : () {
                          if (isAuthenticated) {
                            // Muestra diálogo de confirmación
                            showDialog(
                              context: context,
                              builder:
                                  (dialogContext) => AlertDialog(
                                    title: const Text('Confirmar Compra'),
                                    content: Text(
                                      '¿Estás seguro de que quieres comprar el ${product.brand} ${product.model}?',
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
                                        // Usa FilledButton para destacar la acción principal
                                        onPressed: () {
                                          // Dispara el evento de compra
                                          context.read<ProductDetailBloc>().add(
                                            BuyNowSubmitted(),
                                          );
                                          Navigator.of(
                                            dialogContext,
                                          ).pop(); // Cierra el diálogo
                                        },
                                        child: const Text('Confirmar'),
                                      ),
                                    ],
                                  ),
                            );
                          } else {
                            // --- CAMBIO AQUÍ: Navega a LoginScreen ---
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                            // ----------------------------------------
                          }
                        },
                child:
                    actionStatus == BidStatus.loading
                        ? const SizedBox(
                          // Spinner más pequeño para el botón
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        : Text(
                          isAuthenticated
                              ? 'COMPRAR AHORA'
                              : 'INICIAR SESIÓN PARA COMPRAR',
                        ),
              ),
            )
          else // Si el estado no es 'active' (ej. 'sold')
            const InfoMessageWidget(
              icon: Icons.check_circle_outline,
              title: 'Producto No Disponible',
              message: 'Este producto ya ha sido vendido.',
            ),
        ],
      ),
    );
  }
}
