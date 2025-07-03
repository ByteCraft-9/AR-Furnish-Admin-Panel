import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'products';
  final String _counterDocPath = 'counters/product_counter';

  // Get all products
  Stream<List<ProductModel>> getProducts() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('id', descending: true) // Order by numeric ID
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get product by ID
  Future<ProductModel?> getProductById(String docId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionPath).doc(docId).get();

      if (doc.exists) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Add new product with auto-incrementing numeric ID
  Future<String> addProduct(ProductModel product) async {
    try {
      // Get the next ID from the counter document
      final counterDoc = await _firestore.doc(_counterDocPath).get();

      if (!counterDoc.exists) {
        // Initialize counter if it doesn't exist
        await _firestore.doc(_counterDocPath).set({'next_id': 1});
      }

      // Get the next ID using a transaction to ensure atomicity
      final nextId = await _firestore.runTransaction<int>((transaction) async {
        final counterSnapshot =
            await transaction.get(_firestore.doc(_counterDocPath));
        final currentId = (counterSnapshot.data()?['next_id'] as int?) ?? 1;

        transaction.update(
            _firestore.doc(_counterDocPath), {'next_id': currentId + 1});

        return currentId;
      });

      // Create a new document with auto-generated Firestore ID
      final docRef = _firestore.collection(_collectionPath).doc();

      // Create product data with the numeric ID
      final productData = product
          .copyWith(
            docId: docRef.id,
            id: nextId,
          )
          .toMap();

      // Save the product
      await docRef.set(productData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Update product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(product.docId)
          .update(product.toMap());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String docId) async {
    try {
      await _firestore.collection(_collectionPath).doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Get products by category
  Stream<List<ProductModel>> getProductsByCategory(String category) {
    return _firestore
        .collection(_collectionPath)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get all available categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_collectionPath).get();

      // Extract all categories and remove duplicates
      final categories = snapshot.docs
          .map((doc) => doc.data()['category'] as String)
          .toSet()
          .toList();

      // Sort categories alphabetically
      categories.sort();

      return categories;
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  // Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    // Firestore doesn't support native text search, so we'll do a simple contains search
    try {
      QuerySnapshot nameSnapshot = await _firestore
          .collection(_collectionPath)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      List<ProductModel> products = nameSnapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      return products;
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Toggle product enabled state
  Future<void> toggleProductEnabledState(String id, bool isEnabled) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(id)
          .update({'is_enabled': isEnabled});
    } catch (e) {
      throw Exception('Failed to update product status: $e');
    }
  }

  // Get only enabled products
  Stream<List<ProductModel>> getEnabledProducts() {
    return _firestore
        .collection(_collectionPath)
        .where('is_enabled', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get only disabled products
  Stream<List<ProductModel>> getDisabledProducts() {
    return _firestore
        .collection(_collectionPath)
        .where('is_enabled', isEqualTo: false)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
