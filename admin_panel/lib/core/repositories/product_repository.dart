import 'dart:io';
import 'package:admin_panel/core/models/bid_model.dart';
import 'package:admin_panel/core/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProductRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Obtiene un stream de todas las pujas para un producto específico,
  /// ordenadas de la más alta a la más baja.
  Stream<List<Bid>> getBidsForProduct(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('bids')
        .orderBy('amount', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Bid.fromSnapshot(doc)).toList();
    });
  }

  /// Reporta un incidente contra un usuario.
  /// Esto crea un nuevo documento en la colección 'incidents'.
  Future<void> reportIncident({
    required String reportedUserId,
    required String productId,
    required String productModel,
    required double bidAmount,
    required String reason,
  }) async {
    try {
      await _firestore.collection('incidents').add({
        'reportedUserId': reportedUserId,
        'productId': productId,
        'productModel': productModel,
        'bidAmount': bidAmount,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al reportar incidente: $e');
      rethrow;
    }
  }

  /// Anula la puja más alta de una subasta.
  /// Esto implica eliminar el documento de la puja y actualizar el producto
  /// para que refleje la nueva puja más alta.
  Future<void> annulBid({
    required String productId,
    required String highestBidId,
  }) async {
    try {
      final productRef = _firestore.collection('products').doc(productId);
      final bidRef = productRef.collection('bids').doc(highestBidId);

      // Obtenemos las pujas restantes para encontrar la nueva más alta.
      final remainingBidsQuery = productRef
          .collection('bids')
          .orderBy('amount', descending: true)
          .where(FieldPath.documentId, isNotEqualTo: highestBidId)
          .limit(1);

      final batch = _firestore.batch();

      // 1. Elimina la puja anulada.
      batch.delete(bidRef);

      // 2. Actualiza el producto con la información de la nueva puja más alta (si existe).
      final remainingBidsSnapshot = await remainingBidsQuery.get();
      if (remainingBidsSnapshot.docs.isNotEmpty) {
        final newHighestBid = Bid.fromSnapshot(remainingBidsSnapshot.docs.first);
        batch.update(productRef, {
          'currentPrice': newHighestBid.amount,
          'highestBidderId': newHighestBid.userId,
        });
      } else {
        // Si no quedan más pujas, reseteamos el estado de la subasta.
        batch.update(productRef, {
          'currentPrice': FirebaseFirestore.instance.doc(productId).get().then((doc) => doc.data()?['initialPrice'] ?? 0),
          'highestBidderId': null,
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error al anular la puja: $e');
      rethrow;
    }
  }

  /// Confirma la venta de un producto.
  /// Cambia el estado del producto a 'sold'.
  Future<void> confirmSale({required String productId}) async {
    try {
      await _firestore.collection('products').doc(productId).update({'status': 'sold'});
    } catch (e) {
      print('Error al confirmar la venta: $e');
      rethrow;
    }
  }

  /// Sube imágenes a Firebase Storage y devuelve sus URLs.
  Future<List<String>> uploadImages(String productId, List<XFile> images) async {
    final List<String> imageUrls = [];
    for (final image in images) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final ref = _storage.ref().child('products/$productId/$fileName');
      try {
        final uploadTask = await ref.putFile(File(image.path));
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      } on FirebaseException catch (e) {
        print('Error al subir imagen: $e');
        // Podrías decidir si continuar o lanzar una excepción.
        // Por ahora, continuamos con las siguientes imágenes.
      }
    }
    return imageUrls;
  }

  /// Guarda (crea o actualiza) un producto.
  Future<void> saveProduct({
    required Map<String, dynamic> productData,
    String? productId,
  }) async {
    if (productId != null) {
      // Actualiza un producto existente
      await _firestore.collection('products').doc(productId).update(productData);
    } else {
      // Crea un nuevo producto
      await _firestore.collection('products').add(productData);
    }
  }

  /// Elimina un producto.
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  /// Obtiene un stream de todos los productos para el dashboard del admin.
  Stream<List<Product>> getAllProductsForAdmin() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
    });
  }
}