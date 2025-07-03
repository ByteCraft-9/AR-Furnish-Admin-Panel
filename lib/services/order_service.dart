import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'orders';
  final String _notificationsCollection = 'notifications';

  // Get all orders
  Stream<List<Map<String, dynamic>>> getOrders() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Offer to create sample orders for testing
        _createSampleOrders();
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Debug the data structure of orders

        // Check for common fields
        if (!data.containsKey('orderDate') && !data.containsKey('createdAt')) {}

        if (!data.containsKey('status')) {
          data['status'] = 'Pending';
        }

        if (!data.containsKey('total')) {}

        if (!data.containsKey('items') ||
            (data['items'] as List?)?.isEmpty == true) {}

        return data;
      }).toList();
    });
  }

  // Get order by ID
  Future<Map<String, dynamic>?> getOrderById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionPath).doc(id).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String id, String status) async {
    try {
      // First fetch the order to get the current status and user info
      final orderDoc =
          await _firestore.collection(_collectionPath).doc(id).get();

      if (!orderDoc.exists) {
        return false;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final previousStatus = orderData['status'] as String? ?? 'Unknown';
      final userId = orderData['userId'] as String? ?? 'unknown_user';
      final orderId = id;

      // Update the order status
      await _firestore.collection(_collectionPath).doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create a notification for the status change
      await _createStatusChangeNotification(
          orderId: orderId,
          userId: userId,
          previousStatus: previousStatus,
          newStatus: status);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Create notification for order status change
  Future<void> _createStatusChangeNotification({
    required String orderId,
    required String userId,
    required String previousStatus,
    required String newStatus,
  }) async {
    final notificationData = {
      'userId': userId,
      'orderId': orderId,
      'type': 'ORDER_STATUS_CHANGE',
      'title': 'Order Status Changed',
      'message':
          'Your order #${orderId.substring(0, 8)} has been updated from $previousStatus to $newStatus',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': {
        'orderId': orderId,
        'previousStatus': previousStatus,
        'newStatus': newStatus,
      },
    };

    await _firestore.collection(_notificationsCollection).add(notificationData);
  }

  // Get count of new/pending orders
  Future<int> getNewOrdersCount() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionPath)
          .where('status', isEqualTo: 'Pending')
          .get();
      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  // Create sample orders for testing
  Future<void> _createSampleOrders() async {
    final random = math.Random();
    final statuses = [
      'Pending',
      'Confirmed',
      'Processing',
      'Shipped',
      'Delivered',
      'Cancelled'
    ];
    final products = [
      {
        'productId': 'sample_product_1',
        'productName': 'Classic Cotton T-Shirt',
        'productImage':
            'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?q=80&w=1400&auto=format&fit=crop',
        'price': 24.99,
      },
      {
        'productId': 'sample_product_2',
        'productName': 'Slim Fit Jeans',
        'productImage':
            'https://images.unsplash.com/photo-1582552938357-32b906df40cb?q=80&w=1400&auto=format&fit=crop',
        'price': 49.99,
      },
      {
        'productId': 'sample_product_3',
        'productName': 'Leather Wallet',
        'productImage':
            'https://images.unsplash.com/photo-1614331586258-96c197ae7fcd?q=80&w=1400&auto=format&fit=crop',
        'price': 29.99,
      },
      {
        'productId': 'sample_product_4',
        'productName': 'Wireless Headphones',
        'productImage':
            'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?q=80&w=1400&auto=format&fit=crop',
        'price': 79.99,
      },
      {
        'productId': 'sample_product_5',
        'productName': 'Smartwatch',
        'productImage':
            'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?q=80&w=1400&auto=format&fit=crop',
        'price': 149.99,
      },
    ];

    // Generate 5 sample orders
    for (int i = 0; i < 5; i++) {
      final now = DateTime.now();
      final orderDate = now.subtract(Duration(days: random.nextInt(30)));

      // Create a random number of items (1-3)
      final numItems = random.nextInt(3) + 1;
      final items = <Map<String, dynamic>>[];
      double subtotal = 0;

      // Add random products
      for (int j = 0; j < numItems; j++) {
        final product = products[random.nextInt(products.length)];
        final quantity = random.nextInt(3) + 1;
        final itemTotal = (product['price'] as double) * quantity;
        subtotal += itemTotal;

        items.add({
          'productId': product['productId'],
          'productName': product['productName'],
          'productImage': product['productImage'],
          'price': product['price'],
          'quantity': quantity,
          'total': itemTotal,
        });
      }

      // Calculate order totals
      const shipping = 5.99;
      final tax = subtotal * 0.1;
      final total = subtotal + shipping + tax;

      // Generate random status based on order age
      final daysAgo = now.difference(orderDate).inDays;
      String status;
      if (daysAgo > 20) {
        // Older orders are more likely to be completed
        status = random.nextInt(10) < 8
            ? 'Delivered'
            : statuses[random.nextInt(statuses.length)];
      } else if (daysAgo > 10) {
        // Medium age orders are in the middle of the process
        status = statuses[random.nextInt(4) +
            1]; // Confirmed, Processing, Shipped or Delivered
      } else {
        // Recent orders are more likely to be pending
        status =
            statuses[random.nextInt(3)]; // Pending, Confirmed or Processing
      }

      // Create the order document
      final docRef = await _firestore.collection(_collectionPath).add({
        'userId': 'test_user_${random.nextInt(100)}',
        'userName': 'Test User',
        'userEmail': 'testuser${random.nextInt(100)}@example.com',
        'userPhone':
            '+92 ${300 + random.nextInt(100)} ${1000000 + random.nextInt(9000000)}',
        'shippingAddress':
            '${random.nextInt(1000)} Main Street, Apartment ${random.nextInt(100)}, Islamabad, Pakistan',
        'subtotal': subtotal,
        'shipping': shipping,
        'tax': tax,
        'total': total,
        'status': status,
        'paymentMethod': random.nextBool() ? 'Cash on Delivery' : 'Credit Card',
        'paymentStatus': random.nextBool() ? 'Paid' : 'Pending',
        'items': items,
        'orderDate': Timestamp.fromDate(orderDate),
        'createdAt': Timestamp.fromDate(orderDate),
        'updatedAt': Timestamp.fromDate(
            now.subtract(Duration(days: random.nextInt(daysAgo)))),
      });

      // Create sample notification for the new order
      if (status == 'Pending') {
        await _createStatusChangeNotification(
            orderId: docRef.id,
            userId: 'test_user_${random.nextInt(100)}',
            previousStatus: 'Created',
            newStatus: 'Pending');
      }
    }
  }

  // Method to manually create sample orders (can be called from UI)
  Future<void> createSampleOrders() async {
    await _createSampleOrders();
  }
}
