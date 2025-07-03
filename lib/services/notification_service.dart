import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'notifications';
  final String _preferencesCollectionPath = 'notificationPreferences';

  // Get all notifications for a user
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get notification by ID
  Future<NotificationModel?> getNotificationById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionPath).doc(id).get();

      if (doc.exists) {
        return NotificationModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Add new notification
  Future<String> addNotification(NotificationModel notification) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_collectionPath)
          .add(notification.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add notification: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      // Get all unread notifications for the user
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Create a batch to update all documents at once
      WriteBatch batch = _firestore.batch();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Get unread notifications count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.size;
    } catch (e) {
      return 0;
    }
  }

  // Get notification preferences for a user
  Future<Map<String, dynamic>?> getNotificationSettings(String userId) async {
    try {
      DocumentSnapshot docSnapshot = await _firestore
          .collection(_preferencesCollectionPath)
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      }

      // If no settings found, return default settings
      return {
        'orderNotifications': true,
        'productUpdateNotifications': true,
        'promotionNotifications': true,
        'systemNotifications': true,
        'emailOrderNotifications': true,
        'emailNewProductNotifications': false,
        'emailPromotionNotifications': true,
        'emailNewsletterNotifications': false,
        'soundEnabled': true,
        'vibrationEnabled': true,
        'notificationDisplayDuration': 5,
      };
    } catch (e) {
      throw Exception('Failed to get notification settings: $e');
    }
  }

  // Save notification preferences for a user
  Future<void> saveNotificationSettings(
      String userId, Map<String, dynamic> settings) async {
    try {
      await _firestore
          .collection(_preferencesCollectionPath)
          .doc(userId)
          .set(settings, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save notification settings: $e');
    }
  }
}
