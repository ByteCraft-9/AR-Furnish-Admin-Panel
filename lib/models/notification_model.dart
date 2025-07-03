import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String? orderId;
  final String type; // ORDER_STATUS_CHANGE, NEW_ORDER, etc.
  final String title;
  final String message;
  final bool isRead;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    this.orderId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.timestamp,
    this.metadata,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime timestamp;
    if (map['timestamp'] is Timestamp) {
      timestamp = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is Map &&
        map['timestamp'].containsKey('seconds')) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(
          (map['timestamp']['seconds'] as int) * 1000);
    } else {
      timestamp = DateTime.now();
    }

    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      orderId: map['orderId'],
      type: map['type'] ?? 'UNKNOWN',
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? '',
      isRead: map['isRead'] ?? false,
      timestamp: timestamp,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orderId': orderId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': isRead,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? orderId,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}
