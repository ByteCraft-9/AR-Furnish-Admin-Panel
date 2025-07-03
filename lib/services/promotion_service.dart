import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promotion_model.dart';

class PromotionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'promotion';

  // Get all promotions
  Stream<List<PromotionModel>> getPromotions() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('promotion_name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PromotionModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get promotion by ID
  Future<PromotionModel?> getPromotionById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionPath).doc(id).get();

      if (doc.exists) {
        return PromotionModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get promotion: $e');
    }
  }

  // Add new promotion
  Future<String> addPromotion(PromotionModel promotion) async {
    try {
      DocumentReference docRef =
          await _firestore.collection(_collectionPath).add(promotion.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add promotion: $e');
    }
  }

  // Update promotion
  Future<void> updatePromotion(PromotionModel promotion) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(promotion.id)
          .update(promotion.toMap());
    } catch (e) {
      throw Exception('Failed to update promotion: $e');
    }
  }

  // Delete promotion
  Future<void> deletePromotion(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete promotion: $e');
    }
  }
}
