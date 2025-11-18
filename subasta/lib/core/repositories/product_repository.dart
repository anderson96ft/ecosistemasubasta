// lib/core/repositories/product_repository.dart

import 'package:subasta/core/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:subasta/core/models/bid_model.dart'; // <-- AÑADE ESTA IMPORTACIÓN

enum SeederScenario {
  clean, // Borra todo y añade una mezcla de productos activos
  userIsWinning, // Como 'clean', pero el usuario actual va ganando una subasta
  userIsLosing, // Como 'clean', pero el usuario actual va en 2º lugar en una subasta
  userHasWon, // Añade una subasta finalizada que el usuario actual ganó
  userHasPurchased, // Añade un producto de venta directa que el usuario actual compró
}

class ProductRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  ProductRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  /// Llama a la Cloud Function 'buyNow' para comprar un producto.
  Future<void> buyNow({required String productId}) async {
    try {
      final callable = _functions.httpsCallable('buyNow');
      final result = await callable.call<Map<String, dynamic>>({
        'productId': productId,
      });
      print('Resultado de la función buyNow: ${result.data['message']}');
    } on FirebaseFunctionsException catch (e) {
      print('Error desde la Cloud Function: [${e.code}] ${e.message}');
      rethrow;
    } catch (e) {
      print('Error genérico al llamar a buyNow: $e');
      throw Exception('Error de conexión. Por favor, inténtalo de nuevo.');
    }
  }

  Stream<List<Product>> getAvailableProducts() {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
        });
  }

  Stream<Product> getProductById(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .snapshots()
        .map((snapshot) => Product.fromSnapshot(snapshot));
  }

  Stream<List<Product>> getActiveBidsForUser(String userId) {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'active')
        .where('highestBidderId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
        });
  }

  /// Devuelve un Stream de subastas pendientes de confirmación en las que el usuario ha participado.
  Stream<List<Product>> getPendingConfirmationAuctionsForUser(String userId) {
    if (userId.isEmpty)
      return Stream.value([]); // Devuelve stream vacío si no hay usuario
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'pending_confirmation')
        .where(
          'bidderIds',
          arrayContains: userId,
        ) // Busca el ID del usuario en el array
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList(),
        );
  }

  Stream<List<Product>> getWonAuctionsForUser(String userId) {
    return _firestore
        .collection('products')
        // --- CORRECCIÓN ---
        // Un producto ganado puede tener estado 'finished' o 'pending_confirmation'.
        // Buscamos en ambos.
        .where('status', whereIn: ['finished', 'pending_confirmation', 'sold'])
        .where('winnerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
        });
  }

  Future<void> placeBid({
    required String productId,
    required double amount,
  }) async {
    try {
      final callable = _functions.httpsCallable('placeBid');
      final result = await callable.call<Map<String, dynamic>>({
        'productId': productId,
        'bidAmount': amount,
      });
      print('Resultado de la función: ${result.data['message']}');
    } on FirebaseFunctionsException catch (e) {
      print('Error desde la Cloud Function: [${e.code}] ${e.message}');
      rethrow;
    } catch (e) {
      print('Error genérico al llamar a placeBid: $e');
      throw Exception('Error de conexión. Por favor, inténtalo de nuevo.');
    }
  }

  // === NUEVO MÉTODO PARA OBTENER EL HISTORIAL DE PUJAS ===
  /// Devuelve un Stream del historial de pujas para un producto específico,
  /// ordenadas de la más alta a la más baja.
  Stream<List<Bid>> getBidsForProduct(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('bids')
        .orderBy('amount', descending: true) // Ordena de mayor a menor
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Bid.fromSnapshot(doc)).toList();
        });
  }

  // ========================================================================
  // ===     NUEVO MÉTODO DE SEMBRADO AVANZADO (REEMPLAZA A seedDatabase)  ===
  // ========================================================================
  Future<void> seedDatabase({
    required SeederScenario scenario,
    required String
    currentUserId, // Necesitamos el ID del usuario para los escenarios
    required String
    otherUserId, // Un ID de otro usuario para simular competencia
  }) async {
    print("Iniciando sembrado para el escenario: $scenario");
    final collectionRef = _firestore.collection('products');

    // 1. Borrar todos los productos existentes
    final existingProducts = await collectionRef.get();
    final batch = _firestore.batch();
    for (final doc in existingProducts.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    print("Productos antiguos borrados.");

    // 2. Definir los productos base
    List<Map<String, dynamic>> productsToSeed = [
      // Subasta activa
      {
        'brand': 'Apple',
        'model': 'iPhone 15 Pro',
        'status': 'active',
        'saleType': 'auction',
        'condition': 'Nuevo', 'storage': '256GB', 'currentPrice': 850.00,
        'endTime': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 2)),
        ),
        'createdAt': Timestamp.now(), // <-- AÑADE FECHA DE CREACIÓN
        'imageUrls': [
          'https://upload.wikimedia.org/wikipedia/en/1/1e/Hunter-x-hunter-phantom-rouge-poster.png',
        ],
        'sellerId': 'mi_empresa_id',
        'highestBidderId': otherUserId, // Otro usuario va ganando por defecto
      },
      // Venta directa activa
      {
        'brand': 'Samsung',
        'model': 'Galaxy S24 Ultra',
        'status': 'active',
        'saleType': 'directSale',
        'condition': 'Como Nuevo',
        'storage': '512GB',
        'fixedPrice': 1100.00,
        'createdAt': Timestamp.now(), // <-- AÑADE FECHA DE CREACIÓN
        'imageUrls': [
          'https://upload.wikimedia.org/wikipedia/en/1/1e/Hunter-x-hunter-phantom-rouge-poster.png',
        ],
        'sellerId': 'mi_empresa_id',
      },
      // Otra subasta activa
      {
        'brand': 'Google',
        'model': 'Pixel 8 Pro',
        'status': 'active',
        'saleType': 'auction',
        'condition': 'Excelente',
        'storage': '128GB',
        'currentPrice': 720.00,
        'endTime': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 12)),
        ),
        'createdAt': Timestamp.now(), // <-- AÑADE FECHA DE CREACIÓN
        'imageUrls': [
          'https://upload.wikimedia.org/wikipedia/en/1/1e/Hunter-x-hunter-phantom-rouge-poster.png',
        ],
        'sellerId': 'mi_empresa_id',
        'highestBidderId': null,
      },
    ];

    // 3. Modificar los datos según el escenario
    switch (scenario) {
      case SeederScenario.clean:
        // No hace nada, usa los datos base
        break;
      case SeederScenario.userIsWinning:
        // El usuario actual es el ganador del iPhone
        productsToSeed[0]['highestBidderId'] = currentUserId;
        productsToSeed[0]['currentPrice'] = 860.00;
        break;
      case SeederScenario.userIsLosing:
        // El usuario actual es el segundo en el iPhone
        // (La lógica de subcolección de pujas lo mostraría en segundo lugar)
        // Por simplicidad, aquí solo nos aseguramos de que no sea el ganador.
        productsToSeed[0]['highestBidderId'] = otherUserId;
        break;
      case SeederScenario.userHasWon:
        // --- LÓGICA MEJORADA ---
        // Modificamos una subasta existente para que sea más realista.
        // El usuario actual gana el iPhone.
        productsToSeed[0]['status'] = 'pending_confirmation';
        productsToSeed[0]['winnerId'] = currentUserId;
        productsToSeed[0]['highestBidderId'] = currentUserId;
        productsToSeed[0]['currentPrice'] = 860.00;
        // Simulamos que la subasta terminó hace una hora.
        productsToSeed[0]['endTime'] = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1)));
        break;
      case SeederScenario.userHasPurchased:
        // Añade un producto que el usuario ya compró
        productsToSeed.add({
          'brand': 'Xiaomi',
          'model': '14',
          'status': 'sold',
          'saleType': 'directSale',
          'condition': 'Nuevo', 'storage': '256GB', 'fixedPrice': 799.00,
          'buyerId': currentUserId, // El usuario actual es el comprador
          'imageUrls': [], 'sellerId': 'mi_empresa_id',
          'createdAt': Timestamp.now(), // <-- AÑADE FECHA DE CREACIÓN
        });
        break;
    }

    // 4. Guardar los datos en Firestore
    final finalBatch = _firestore.batch();
    for (final productData in productsToSeed) {
      final docRef = collectionRef.doc();
      finalBatch.set(docRef, productData);

      // --- AÑADIMOS LA PUJA SIMULADA ---
      // Si estamos en el escenario de 'userHasWon' y este es el producto modificado,
      // le añadimos una puja para que el historial sea coherente.
      if (scenario == SeederScenario.userHasWon && productData['model'] == 'iPhone 15 Pro') {
        final bidRef = docRef.collection('bids').doc();
        finalBatch.set(bidRef, {
          'userId': currentUserId, 'amount': 860.00, 'timestamp': Timestamp.now(),
        });
      }
    }
    await finalBatch.commit();
    print("¡Sembrado para el escenario $scenario completado!");
  }

  // === NUEVO MÉTODO: OBTENER COMPRAS DIRECTAS DEL USUARIO ===
  /// Devuelve un Stream de productos que el usuario ha comprado directamente.
  Stream<List<Product>> getDirectPurchasesForUser(String userId) {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'sold') // El producto debe estar vendido
        .where('buyerId', isEqualTo: userId) // El usuario debe ser el comprador
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
        });
  }
}
