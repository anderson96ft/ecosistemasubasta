import 'dart:async';
import 'package:admin_panel/core/models/product_model.dart';
import 'package:admin_panel/core/models/user_details_model.dart';
import 'package:admin_panel/core/repositories/auth_repository.dart';
import 'package:admin_panel/core/repositories/product_repository.dart';
import 'package:admin_panel/features/dashboard/presentation/screens/add_edit_product_screen.dart';
import 'package:admin_panel/features/dashboard/presentation/screens/auction_confirmation_screen.dart';
import 'package:admin_panel/features/dashboard/presentation/screens/auction_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

// 1. Estado para el Cubit de Productos
@immutable
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> allProducts;
  final List<Product> filteredProducts;

  ProductLoaded({required this.allProducts, required this.filteredProducts});
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}

// 2. Cubit para manejar la lógica de carga de productos
class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;
  StreamSubscription? _productSubscription;
  List<Product> _allProducts = [];

  ProductCubit(this._productRepository) : super(ProductInitial());

  void subscribeToProducts() {
    emit(ProductLoading());
    try {
      _productSubscription = _productRepository.getAllProductsForAdmin().listen(
        (products) {
          _allProducts = products;
          emit(
            ProductLoaded(
              allProducts: _allProducts,
              filteredProducts: _allProducts,
            ),
          );
        },
        onError: (error) {
          emit(ProductError(error.toString()));
        },
      );
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  void filterProducts(String query) {
    final currentState = state;
    if (currentState is ProductLoaded) {
      final filtered =
          _allProducts.where((product) {
            return product.model.toLowerCase().contains(query.toLowerCase());
          }).toList();
      emit(
        ProductLoaded(allProducts: _allProducts, filteredProducts: filtered),
      );
    }
  }

  void sortProducts(int columnIndex, bool ascending) {
    final currentState = state;
    if (currentState is ProductLoaded) {
      final sortedList = List<Product>.from(currentState.filteredProducts);

      // Función de comparación
      int Function(Product, Product) compare;

      switch (columnIndex) {
        case 0: // Modelo
          compare = (a, b) => a.model.compareTo(b.model);
          break;
        case 1: // Precio
          compare =
              (a, b) => (a.currentPrice ?? a.fixedPrice ?? 0).compareTo(
                b.currentPrice ?? b.fixedPrice ?? 0,
              );
          break;
        case 3: // Estado
          compare = (a, b) => (a.status ?? '').compareTo(b.status ?? '');
          break;
        default:
          return; // No ordenar para otras columnas
      }

      sortedList.sort(
        ascending ? (a, b) => compare(a, b) : (a, b) => compare(b, a),
      );

      // Emitimos el nuevo estado con la lista ordenada
      emit(
        ProductLoaded(allProducts: _allProducts, filteredProducts: sortedList),
      );
    }
  }

  // --- NUEVO: MÉTODO PARA ELIMINAR UN PRODUCTO ---
  Future<void> deleteProduct(String productId) async {
    try {
      await _productRepository.deleteProduct(productId);
      // El stream actualizará la lista automáticamente, no es necesario emitir estado aquí.
    } catch (e) {
      // Opcional: emitir un estado de error específico para la eliminación si se desea.
      print("Error al eliminar producto: $e");
    }
  }

  @override
  Future<void> close() {
    _productSubscription?.cancel();
    return super.close();
  }
}

// --- PANTALLA PRINCIPAL MEJORADA ---
class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Llamamos al nuevo método que se suscribe al Stream
      create:
          (context) =>
              ProductCubit(context.read<ProductRepository>())
                ..subscribeToProducts(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Productos y Subastas'),
          automaticallyImplyLeading: false,
          // --- NUEVO: Barra de búsqueda ---
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por modelo...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  context.read<ProductCubit>().filterProducts(value);
                },
              ),
            ),
          ),
        ),
        body: BlocBuilder<ProductCubit, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProductError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is ProductLoaded) {
              if (state.filteredProducts.isEmpty) {
                return const Center(
                  child: Text('No hay productos para mostrar.'),
                );
              }
              // --- NUEVO: DataTable ---
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    headingRowColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                    columns: [
                      DataColumn(
                        label: const Text('Modelo'),
                        onSort: (columnIndex, ascending) {
                          setState(() {
                            _sortColumnIndex = columnIndex;
                            _sortAscending = ascending;
                          });
                          context.read<ProductCubit>().sortProducts(
                            columnIndex,
                            ascending,
                          );
                        },
                      ),
                      DataColumn(
                        label: const Text('Precio'),
                        numeric: true,
                        onSort: (columnIndex, ascending) {
                          setState(() {
                            _sortColumnIndex = columnIndex;
                            _sortAscending = ascending;
                          });
                          context.read<ProductCubit>().sortProducts(
                            columnIndex,
                            ascending,
                          );
                        },
                      ),
                      const DataColumn(label: Text('Tipo Venta')),
                      DataColumn(
                        label: const Text('Estado'),
                        onSort: (columnIndex, ascending) {
                          setState(() {
                            _sortColumnIndex = columnIndex;
                            _sortAscending = ascending;
                          });
                          context.read<ProductCubit>().sortProducts(
                            columnIndex,
                            ascending,
                          );
                        },
                      ),
                      const DataColumn(label: Text('Acciones')),
                    ],
                    rows:
                        state.filteredProducts
                            .map(
                              (product) => _ProductTableRow(
                                context: context,
                                product: product,
                              ),
                            )
                            .toList(),
                  ),
                ),
              );
            }
            return const Center(child: Text('Iniciando...'));
          },
        ),
        // --- NUEVO: Botón para añadir productos ---
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
            );
          },
          child: const Icon(Icons.add),
          tooltip: 'Añadir Producto',
        ),
      ),
    );
  }
}

// --- NUEVO: Widget para construir cada fila de la tabla ---
DataRow _ProductTableRow({
  required BuildContext context,
  required Product product,
}) {
  final isFinished = product.status == 'finished';
  final isSold = product.status == 'sold';
  final isAuction = product.saleType == SaleType.auction;

  double? displayPrice;
  if (product.saleType == SaleType.auction) {
    displayPrice = product.currentPrice;
  } else if (product.saleType == SaleType.directSale) {
    displayPrice = product.fixedPrice;
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'finished':
        return Colors.blue;
      case 'sold':
        return Colors.grey;
      case 'pending_confirmation':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  return DataRow(
    cells: [
      DataCell(
        Text(
          product.model,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      DataCell(
        Text(
          displayPrice != null ? '\$${displayPrice.toStringAsFixed(2)}' : 'N/A',
        ),
      ),
      DataCell(
        Text(
          product.saleType == SaleType.auction ? 'Subasta' : 'Venta Directa',
        ),
      ),
      DataCell(
        Chip(
          label: Text(
            product.status?.replaceAll('_', ' ').toUpperCase() ?? 'N/A',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: getStatusColor(product.status),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      DataCell(
        Row(
          children: [
            // --- NUEVO: Botón para ver detalles de la subasta o del comprador ---
            if (isAuction)
              Tooltip(
                message: 'Detalles de la Subasta',
                child: IconButton(
                  icon: const Icon(Icons.list_alt, color: Colors.purple),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AuctionDetailsScreen(product: product),
                      ),
                    );
                  },
                ),
              ),
            if (isSold && product.buyerId != null)
              Tooltip(
                message: 'Ver Comprador',
                child: IconButton(
                  icon: const Icon(Icons.person_search, color: Colors.teal),
                  onPressed: () {
                    showUserDetailsDialog(
                      context,
                      product.buyerId!,
                      'Comprador',
                    );
                  },
                ),
              ),

            if (isFinished)
              Tooltip(
                message: 'Gestionar Subasta',
                child: IconButton(
                  icon: const Icon(Icons.gavel),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => AuctionConfirmationScreen(product: product),
                      ),
                    );
                  },
                ),
              ),
            Tooltip(
              message: 'Editar Producto',
              child: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditProductScreen(product: product),
                    ),
                  );
                },
              ),
            ),
            Tooltip(
              message: 'Eliminar Producto',
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed:
                    () => _showDeleteConfirmationDialog(context, product.id),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

void showUserDetailsDialog(BuildContext context, String userId, String title) {
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
                ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user.name ?? 'Nombre no disponible')),
                ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(user.email ?? 'Email no disponible')),
                ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(user.phone ?? 'Teléfono no disponible')),
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

void _showDeleteConfirmationDialog(BuildContext context, String productId) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este producto? Esta acción no se puede deshacer.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () {
              // Usamos el Cubit para llamar a la lógica de negocio
              context.read<ProductCubit>().deleteProduct(productId);
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}
