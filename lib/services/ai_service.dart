import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_model.dart';

class AIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all AI models
  Stream<List<AIModelData>> getAIModels() {
    return _firestore
        .collection('AI_Model')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AIModelData.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get AI models by theme
  Stream<List<AIModelData>> getAIModelsByTheme(String theme) {
    return _firestore
        .collection('AI_Model')
        .where('theme', isEqualTo: theme)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AIModelData.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get AI models by date range
  Stream<List<AIModelData>> getAIModelsByDateRange(
      DateTime startDate, DateTime endDate) {
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);

    return _firestore
        .collection('AI_Model')
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .where('createdAt', isLessThanOrEqualTo: endTimestamp)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AIModelData.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get AI models by user ID
  Stream<List<AIModelData>> getAIModelsByUser(String userId) {
    return _firestore
        .collection('AI_Model')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AIModelData.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get unique themes
  Future<List<String>> getUniqueThemes() async {
    final snapshot = await _firestore.collection('AI_Model').get();
    final themes = snapshot.docs
        .map((doc) => doc.data()['theme'] as String)
        .toSet()
        .toList();
    return themes;
  }

  // Get user name by user ID
  Future<String?> getUserName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        // Assuming user document has a "name" field
        return userData?['name'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching user name: $e');
      return null;
    }
  }
}
