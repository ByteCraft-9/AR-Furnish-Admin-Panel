import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'users';

  // Get all users with optional filtering
  Stream<List<UserModel>> getUsers({
    String? role,
    bool? isActive,
    String? searchQuery,
  }) {
    try {
      Query query = _firestore.collection(_collectionPath);

      // Apply filters
      if (role != null) {
        query = query.where('role', isEqualTo: role);
        // Skip ordering when filtering by role to avoid index requirements
      } else {
        // Only add ordering when not using role filter
        query = query.orderBy('createdAt', descending: true);
      }

      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      return query.snapshots().map((snapshot) {
        final users = snapshot.docs.map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return UserModel.fromJson(data);
          } catch (e) {
            // Return a placeholder user for documents that fail to parse
            // This prevents one bad document from breaking the whole stream
            return UserModel(
              id: doc.id,
              name: "Error parsing user",
              email: "error@example.com",
              role: "unknown",
              isActive: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
        }).toList();

        // Apply search filter (can't be done in Firestore query)
        if (searchQuery != null && searchQuery.isNotEmpty) {
          return users.where((user) {
            final name = user.name.toLowerCase();
            final email = user.email.toLowerCase();
            final query = searchQuery.toLowerCase();
            return name.contains(query) || email.contains(query);
          }).toList();
        }

        return users;
      });
    } catch (e) {
      // Return an empty stream with error
      return Stream.error(e);
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionPath).doc(id).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create new user
  Future<String?> createUser(UserModel user) async {
    try {
      // Check if email already exists
      QuerySnapshot existingUsers = await _firestore
          .collection(_collectionPath)
          .where('email', isEqualTo: user.email)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        throw Exception('A user with this email already exists.');
      }

      // Create the user document
      DocumentReference docRef =
          await _firestore.collection(_collectionPath).add({
        'name': user.name,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'role': user.role,
        'phone': user.phone,
        'address': user.address,
        'isActive': user.isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection(_collectionPath).doc(user.id).update({
        'name': user.name,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'role': user.role,
        'phone': user.phone,
        'address': user.address,
        'isActive': user.isActive,
        'permissions': user.permissions,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update user permissions
  Future<void> updateUserPermissions(
      String userId, Map<String, bool> permissions) async {
    try {
      await _firestore.collection(_collectionPath).doc(userId).update({
        'permissions': permissions,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user permissions
  Future<Map<String, bool>?> getUserPermissions(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionPath).doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['permissions'] != null) {
          return Map<String, bool>.from(data['permissions']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Delete user
  Future<void> deleteUser(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Suspend/Unsuspend user
  Future<void> toggleUserStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get monthly user registrations for the last year
  Future<Map<String, int>> getUserRegistrationsByMonth() async {
    try {
      // Get date one year ago
      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));

      // Query users registered in the last year
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionPath)
          .where('createdAt', isGreaterThanOrEqualTo: oneYearAgo)
          .get();

      // Initialize monthly counts
      Map<String, int> monthlyCounts = {};
      for (int i = 0; i < 12; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthYear = '${date.month}-${date.year}';
        monthlyCounts[monthYear] = 0;
      }

      // Count users by registration month
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        DateTime createdAt;

        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is Map &&
            data['createdAt'].containsKey('_seconds')) {
          createdAt = DateTime.fromMillisecondsSinceEpoch(
              (data['createdAt']['_seconds'] as int) * 1000);
        } else {
          continue; // Skip if date format is unknown
        }

        final monthYear = '${createdAt.month}-${createdAt.year}';
        if (monthlyCounts.containsKey(monthYear)) {
          monthlyCounts[monthYear] = (monthlyCounts[monthYear] ?? 0) + 1;
        }
      }

      return monthlyCounts;
    } catch (e) {
      return {};
    }
  }

  // Get user roles distribution
  Future<Map<String, int>> getUserRolesDistribution() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection(_collectionPath).get();

      Map<String, int> roleCounts = {
        'admin': 0,
        'manager': 0,
        'staff': 0,
        'customer': 0,
        'other': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String role = data['role'] ?? 'other';

        if (roleCounts.containsKey(role)) {
          roleCounts[role] = (roleCounts[role] ?? 0) + 1;
        } else {
          roleCounts['other'] = (roleCounts['other'] ?? 0) + 1;
        }
      }

      return roleCounts;
    } catch (e) {
      return {};
    }
  }
}
