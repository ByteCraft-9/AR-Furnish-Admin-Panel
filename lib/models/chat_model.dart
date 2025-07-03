import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants; // List of user IDs
  final String chatType; // 'customer', 'manager', 'group'
  final String lastMessage;
  final DateTime lastMessageTimestamp;
  final Map<String, int> unreadCount; // Map of userID -> unread count
  final Map<String, dynamic>? metadata;

  ChatModel({
    required this.id,
    required this.participants,
    required this.chatType,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.unreadCount,
    this.metadata,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime lastMessageTimestamp;
    if (map['lastMessageTimestamp'] is Timestamp) {
      lastMessageTimestamp =
          (map['lastMessageTimestamp'] as Timestamp).toDate();
    } else if (map['lastMessageTimestamp'] is Map &&
        map['lastMessageTimestamp'].containsKey('seconds')) {
      lastMessageTimestamp = DateTime.fromMillisecondsSinceEpoch(
          (map['lastMessageTimestamp']['seconds'] as int) * 1000);
    } else {
      lastMessageTimestamp = DateTime.now();
    }

    // Safely parse participants list
    List<String> participants = [];
    if (map['participants'] != null) {
      participants = List<String>.from(map['participants']);
    }

    // Safely parse unreadCount map
    Map<String, int> unreadCount = {};
    if (map['unreadCount'] != null) {
      map['unreadCount'].forEach((key, value) {
        unreadCount[key] = value as int;
      });
    }

    return ChatModel(
      id: id,
      participants: participants,
      chatType: map['chatType'] ?? 'customer',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTimestamp: lastMessageTimestamp,
      unreadCount: unreadCount,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'chatType': chatType,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': Timestamp.fromDate(lastMessageTimestamp),
      'unreadCount': unreadCount,
      'metadata': metadata,
    };
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? chatType,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
    Map<String, int>? unreadCount,
    Map<String, dynamic>? metadata,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      chatType: chatType ?? this.chatType,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final String? attachment; // URL to attachment if any
  final String? attachmentType; // 'image', 'file', etc.
  final bool isRead;
  final Map<String, dynamic>? metadata;

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.attachment,
    this.attachmentType,
    required this.isRead,
    this.metadata,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
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

    return ChatMessageModel(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      timestamp: timestamp,
      attachment: map['attachment'],
      attachmentType: map['attachmentType'],
      isRead: map['isRead'] ?? false,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'attachment': attachment,
      'attachmentType': attachmentType,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? message,
    DateTime? timestamp,
    String? attachment,
    String? attachmentType,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      attachment: attachment ?? this.attachment,
      attachmentType: attachmentType ?? this.attachmentType,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}
