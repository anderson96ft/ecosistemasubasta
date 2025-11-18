// lib/features/dashboard/presentation/screens/product_edit_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:admin_panel/core/models/product_model.dart';
import 'package:admin_panel/core/repositories/product_repository.dart';
import 'package:admin_panel/features/dashboard/bloc/product_edit/product_edit_bloc.dart';
import 'package:admin_panel/features/dashboard/bloc/product_edit/product_edit_event.dart';
import 'package:admin_panel/features/dashboard/bloc/product_edit/product_edit_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ProductEditScreen extends StatelessWidget {
  final Product? product;

  const ProductEditScreen({super.key, this.product});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => ProductEditBloc(
            productRepository: context.read<ProductRepository>(),
          ),
      child: ProductEditForm(product: product),
    );
  }
}

class ProductEditForm extends StatefulWidget {
  final Product? product;
  const ProductEditForm({super.key, this.product});

  @override
  State<ProductEditForm> createState() => _ProductEditFormState();
}

class _ProductEditFormState extends State<ProductEditForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _conditionController;
  late TextEditingController _storageController;
  late TextEditingController _currentPriceController;
  late TextEditingController _fixedPriceController;
  late TextEditingController _endTimeController;

  SaleType _saleType = SaleType.auction;
  String? _status = 'active';
  DateTime? _selectedEndTime;

  // Variables de estado para la gestión de imágenes
  List<String> _imageUrls = [];
  final List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImages = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _brandController = TextEditingController(text: p?.brand ?? '');
    _modelController = TextEditingController(text: p?.model ?? '');
    _conditionController = TextEditingController(text: p?.condition ?? '');
    _storageController = TextEditingController(text: p?.storage ?? '');
    _currentPriceController = TextEditingController(
      text: p?.currentPrice?.toString() ?? '',
    );
    _fixedPriceController = TextEditingController(
      text: p?.fixedPrice?.toString() ?? '',
    );

    if (p?.endTime != null) {
      _selectedEndTime = p!.endTime!.toDate();
      _endTimeController = TextEditingController(
        text: DateFormat('yyyy-MM-dd HH:mm').format(_selectedEndTime!),
      );
    } else {
      _endTimeController = TextEditingController();
    }

    _saleType = p?.saleType ?? SaleType.auction;
    _status = p?.status ?? 'active';
    if (p != null) {
      _imageUrls = List.from(p.imageUrls);
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _conditionController.dispose();
    _storageController.dispose();
    _currentPriceController.dispose();
    _fixedPriceController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles);
      });
    }
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploadingImages = true);

    final productRepo = context.read<ProductRepository>();
    final productId = widget.product?.id ?? const Uuid().v4();
    final List<String> newImageUrls = [];

    if (_newImages.isNotEmpty) {
      try {
        newImageUrls.addAll(await productRepo.uploadImages(productId, _newImages));
      } catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir una imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isUploadingImages = false);
        return;
      }
    }

    final allImageUrls = [..._imageUrls, ...newImageUrls];

    final productData = <String, dynamic>{
      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      'condition': _conditionController.text.trim(),
      'storage': _storageController.text.trim(),
      'saleType': _saleType == SaleType.auction ? 'auction' : 'directSale',
      'status': _status,
      'imageUrls': allImageUrls,
      'highestBidderId': widget.product?.highestBidderId,
      'winnerId': widget.product?.winnerId,
      'buyerId': widget.product?.buyerId,
      'sellerId': widget.product?.sellerId ?? 'mi_empresa_id',
    };

    if (_saleType == SaleType.auction) {
      productData['currentPrice'] =
          double.tryParse(_currentPriceController.text) ?? 0.0;
      productData['endTime'] =
          _selectedEndTime != null
              ? Timestamp.fromDate(_selectedEndTime!)
              : null;
      productData['fixedPrice'] = null;
    } else {
      productData['fixedPrice'] =
          double.tryParse(_fixedPriceController.text) ?? 0.0;
      productData['currentPrice'] = null;
      productData['endTime'] = null;
    }

    context.read<ProductEditBloc>().add(
      ProductSaveRequested(
        productData: productData,
        productId: widget.product?.id, // <-- CORRECCIÓN: Usar el ID del producto existente si se está editando
      ),
    );

    setState(() => _isUploadingImages = false);
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    // --- CORRECCIÓN: Asegurarse de que la fecha inicial no sea anterior a la primera fecha seleccionable ---
    final initialPickerDate = (_selectedEndTime != null && _selectedEndTime!.isAfter(now))
        ? _selectedEndTime!
        : now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialPickerDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedEndTime ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _selectedEndTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _endTimeController.text = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).format(_selectedEndTime!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return BlocListener<ProductEditBloc, ProductEditState>(
      listener: (context, state) {
        if (state.status == ProductEditStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Producto guardado con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state.status == ProductEditStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: ${state.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Editar Producto' : 'Añadir Nuevo Producto'),
          actions: [
            BlocBuilder<ProductEditBloc, ProductEditState>(
              builder: (context, state) {
                if (state.status == ProductEditStatus.loading ||
                    _isUploadingImages) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Guardar',
                  onPressed: _onSavePressed,
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'Marca'),
                  ),
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(labelText: 'Modelo'),
                  ),
                  TextFormField(
                    controller: _conditionController,
                    decoration: const InputDecoration(labelText: 'Condición'),
                  ),
                  TextFormField(
                    controller: _storageController,
                    decoration: const InputDecoration(
                      labelText: 'Almacenamiento',
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<SaleType>(
                    value: _saleType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Venta',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: SaleType.auction,
                        child: Text('Subasta'),
                      ),
                      DropdownMenuItem(
                        value: SaleType.directSale,
                        child: Text('Venta Directa'),
                      ),
                    ],
                    onChanged:
                        (value) => setState(
                          () => _saleType = value ?? SaleType.auction,
                        ),
                  ),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Activo')),
                      DropdownMenuItem(
                        value: 'finished',
                        child: Text('Finalizado'),
                      ),
                      DropdownMenuItem(value: 'sold', child: Text('Vendido')),
                    ],
                    onChanged: (value) => setState(() => _status = value),
                  ),
                  const SizedBox(height: 20),
                  if (_saleType == SaleType.auction) ...[
                    TextFormField(
                      controller: _currentPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio de Salida (€)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _endTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Finalización',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: _selectDateTime,
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _fixedPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Fijo (€)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Text(
                    'Imágenes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _imageUrls.length + _newImages.length,
                          itemBuilder: (context, index) {
                            if (index < _imageUrls.length) {
                              final url = _imageUrls[index];
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(url, fit: BoxFit.cover),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      radius: 14,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () => _imageUrls.removeAt(index),
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              final imageData =
                                  _newImages[index - _imageUrls.length];
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(File(imageData.path), fit: BoxFit.cover),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      radius: 14,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () => _newImages.removeAt(
                                                index - _imageUrls.length,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_isUploadingImages)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Añadir Imágenes'),
                            onPressed: _pickImages,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
