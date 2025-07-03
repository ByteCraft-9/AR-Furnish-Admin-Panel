import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ChatModel> _chats = [];
  Map<String, List<ChatMessageModel>> _chatMessages = {};
  bool _isLoading = false;
  String? _error;
  int _totalUnreadCount = 0;

  // Getters
  List<ChatModel> get chats => _chats;
  Map<String, List<ChatMessageModel>> get chatMessages => _chatMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalUnreadCount => _totalUnreadCount;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _chatsSubscription;
  Map<String, StreamSubscription<QuerySnapshot>> _messageSubscriptions = {};

  // Initialize chats for current user
  Future<void> initChats(String userId) async {
    print("ChatProvider.initChats - Starting for user $userId");
    _setLoading(true);

    try {
      // Cancel existing subscription if any
      if (_chatsSubscription != null) {
        print("ChatProvider.initChats - Cancelling existing chat subscription");
        await _chatsSubscription?.cancel();
      }

      print("ChatProvider.initChats - Setting up new chat subscription");
      // Subscribe to chats where user is a participant
      _chatsSubscription = _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        print(
            "ChatProvider.initChats - Received ${snapshot.docs.length} chats");

        _chats = snapshot.docs
            .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
            .toList();

        print(
            "ChatProvider.initChats - Chats loaded: ${_chats.map((c) => c.id).join(', ')}");

        // Calculate total unread messages
        _calculateTotalUnread(userId);

        // Listen to messages for each chat
        _subscribeToMessages();

        _setLoading(false);
        notifyListeners();
      }, onError: (e) {
        print("ChatProvider.initChats - ERROR: ${e.toString()}");
        _setError('Error loading chats: ${e.toString()}');
      });
    } catch (e) {
      print("ChatProvider.initChats - EXCEPTION: ${e.toString()}");
      _setError('Error initializing chats: ${e.toString()}');
    }
  }

  // Calculate total unread messages
  void _calculateTotalUnread(String userId) {
    _totalUnreadCount = 0;
    for (final chat in _chats) {
      _totalUnreadCount += chat.unreadCount[userId] ?? 0;
    }
  }

  // Subscribe to messages for each chat
  void _subscribeToMessages() {
    print(
        "ChatProvider._subscribeToMessages - Starting, chat count: ${_chats.length}");

    // First, cancel existing subscriptions
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();

    // Create new subscriptions for each chat
    for (final chat in _chats) {
      print(
          "ChatProvider._subscribeToMessages - Setting up subscription for chat ${chat.id}");

      _messageSubscriptions[chat.id] = _firestore
          .collection('chatMessages')
          .where('chatId', isEqualTo: chat.id)
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to recent messages
          .snapshots()
          .listen((snapshot) {
        print(
            "ChatProvider._subscribeToMessages - Received ${snapshot.docs.length} messages for chat ${chat.id}");

        _chatMessages[chat.id] = snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
            .toList();

        print(
            "ChatProvider - Message cache updated for chat ${chat.id}, total messages: ${_chatMessages[chat.id]?.length ?? 0}");
        notifyListeners();
      }, onError: (e) {
        print(
            "ChatProvider._subscribeToMessages - ERROR for chat ${chat.id}: $e");
        _setError('Error loading messages: ${e.toString()}');
      });
    }
  }

  // Send a new message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
    String? attachment,
    String? attachmentType,
  }) async {
    try {
      print(
          "ChatProvider.sendMessage - Starting with chatId: $chatId, senderId: $senderId");

      // Get chat document
      print("ChatProvider.sendMessage - Fetching chat document");
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        print("ChatProvider.sendMessage - Chat does not exist: $chatId");
        _setError('Chat does not exist');
        return;
      }

      print("ChatProvider.sendMessage - Chat exists, creating message");
      final chat = ChatModel.fromMap(chatDoc.data()!, chatDoc.id);

      // Create new message
      final newMessage = ChatMessageModel(
        id: '', // Firestore will generate ID
        chatId: chatId,
        senderId: senderId,
        message: message,
        timestamp: DateTime.now(),
        attachment: attachment,
        attachmentType: attachmentType,
        isRead: false,
      );

      // Add message to Firestore
      print("ChatProvider.sendMessage - Adding message to Firestore");
      final messageRef =
          await _firestore.collection('chatMessages').add(newMessage.toMap());
      print(
          "ChatProvider.sendMessage - Message added with ID: ${messageRef.id}");

      // Update unread counts for all participants except sender
      Map<String, int> updatedUnreadCount = Map.from(chat.unreadCount);
      for (final participantId in chat.participants) {
        if (participantId != senderId) {
          updatedUnreadCount[participantId] =
              (updatedUnreadCount[participantId] ?? 0) + 1;
        }
      }

      // Update the chat with last message and timestamp
      print("ChatProvider.sendMessage - Updating chat with last message");
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTimestamp': Timestamp.now(),
        'unreadCount': updatedUnreadCount,
      });

      print("ChatProvider.sendMessage - Message sent successfully");
    } catch (e) {
      print("ChatProvider.sendMessage - ERROR: ${e.toString()}");
      _setError('Error sending message: ${e.toString()}');
    }
  }

  // Create a new chat
  Future<String?> createChat({
    required String currentUserId,
    required List<String> participantIds,
    required String chatType,
    String? initialMessage,
  }) async {
    try {
      print(
          "ChatProvider.createChat - Creating chat between ${participantIds.join(', ')}");

      // Ensure current user is included in participants
      if (!participantIds.contains(currentUserId)) {
        participantIds.add(currentUserId);
      }

      // Create unread map (0 for all participants)
      Map<String, int> unreadCount = {};
      for (final id in participantIds) {
        unreadCount[id] = 0;
      }

      // Create new chat
      final newChat = ChatModel(
        id: '', // Firestore will generate ID
        participants: participantIds,
        chatType: chatType,
        lastMessage: initialMessage ?? '', // Empty by default
        lastMessageTimestamp: DateTime.now(),
        unreadCount: unreadCount,
      );

      // Add to Firestore
      final docRef = await _firestore.collection('chats').add(newChat.toMap());
      print("ChatProvider.createChat - Chat created with ID: ${docRef.id}");

      // Only send initial message if provided
      if (initialMessage != null && initialMessage.trim().isNotEmpty) {
        print(
            "ChatProvider.createChat - Sending initial message: $initialMessage");
        await sendMessage(
          chatId: docRef.id,
          senderId: currentUserId,
          message: initialMessage,
        );
      }

      return docRef.id;
    } catch (e) {
      print("ChatProvider.createChat - ERROR: $e");
      _setError('Error creating chat: ${e.toString()}');
      return null;
    }
  }

  // Mark messages as read
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      // Get the chat
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        return;
      }

      // Update unread count for the user
      Map<String, dynamic> data = chatDoc.data()!;
      Map<String, int> unreadCount =
          Map<String, int>.from(data['unreadCount'] ?? {});
      unreadCount[userId] = 0;

      // Update the chat document
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': unreadCount,
      });

      // Mark all messages as read
      final batch = _firestore.batch();
      final unreadMessages = await _firestore
          .collection('chatMessages')
          .where('chatId', isEqualTo: chatId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Recalculate total unread
      _calculateTotalUnread(userId);
      notifyListeners();
    } catch (e) {
      _setError('Error marking chat as read: ${e.toString()}');
    }
  }

  // Get users for a specific chat type (customers, managers)
  Future<List<UserModel>> getUsersForChat(String chatType) async {
    try {
      String role = chatType == 'manager' ? 'manager' : 'customer';

      print("Fetching users with role: $role");

      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      print("Found ${querySnapshot.docs.length} users with role $role");

      // If no users found, try getting all users (might be missing role field)
      if (querySnapshot.docs.isEmpty) {
        print("No users found with role $role, fetching all users");
        final allUsers = await _firestore.collection('users').get();
        print("Total users in database: ${allUsers.docs.length}");

        // For debug purposes, check roles
        final roles = allUsers.docs
            .map((doc) => doc.data()['role'] ?? 'undefined')
            .toSet()
            .toList();
        print("Available roles in database: $roles");

        // Create a test user if no users are found at all
        if (allUsers.docs.isEmpty) {
          print("No users found at all. Creating a test user");

          // Create a test user that can be used to start a chat with
          final testUser = {
            'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
            'name': chatType == 'manager' ? 'Test Manager' : 'Test Customer',
            'email': 'test${chatType}@example.com',
            'role': role,
            'isActive': true,
            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
          };

          return [UserModel.fromJson(testUser)];
        }

        // Try to find users with the right role, ignoring case
        final usersWithRightRole = allUsers.docs.where((doc) {
          final roleValue = doc.data()['role']?.toString().toLowerCase() ?? '';
          return roleValue.contains(role.toLowerCase());
        }).toList();

        if (usersWithRightRole.isNotEmpty) {
          print(
              "Found ${usersWithRightRole.length} users with role-like $role");
          return usersWithRightRole.map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            return UserModel.fromJson(data);
          }).toList();
        }

        // If still no users, just return the first few users
        if (allUsers.docs.length > 0) {
          print(
              "Using first ${allUsers.docs.length > 3 ? 3 : allUsers.docs.length} users as fallback");
          return allUsers.docs.take(3).map((doc) {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;
            // Override role for this chat
            data['role'] = role;
            return UserModel.fromJson(data);
          }).toList();
        }
      }

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        print(
            "Processing user: ${data['name'] ?? 'Unknown'} with role ${data['role'] ?? 'Unknown'}");
        return UserModel.fromJson(data);
      }).toList();
    } catch (e) {
      print("Error in getUsersForChat: $e");
      _setError('Error getting users: ${e.toString()}');

      // Return a test user as last resort
      final testUser = {
        'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
        'name': chatType == 'manager' ? 'Test Manager' : 'Test Customer',
        'email': 'test${chatType}@example.com',
        'role': chatType == 'manager' ? 'manager' : 'customer',
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      return [UserModel.fromJson(testUser)];
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _error = null;
    }
    notifyListeners();
  }

  // Helper method to set error
  void _setError(String errorMsg) {
    _error = errorMsg;
    _isLoading = false;
    notifyListeners();
  }

  // Cleanup method to dispose of listeners
  @override
  void dispose() {
    _chatsSubscription?.cancel();
    for (final subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }

  // Manually refresh messages for a specific chat
  Future<void> refreshMessages(String chatId) async {
    print(
        "ChatProvider.refreshMessages - Refreshing messages for chat $chatId");

    try {
      // Cancel existing subscription if any
      if (_messageSubscriptions.containsKey(chatId)) {
        print(
            "ChatProvider.refreshMessages - Cancelling existing subscription");
        await _messageSubscriptions[chatId]?.cancel();
        _messageSubscriptions.remove(chatId);
      }

      print("ChatProvider.refreshMessages - Fetching messages from Firestore");
      final messagesSnapshot = await _firestore
          .collection('chatMessages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      print(
          "ChatProvider.refreshMessages - Retrieved ${messagesSnapshot.docs.length} messages");

      _chatMessages[chatId] = messagesSnapshot.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
          .toList();

      // Re-subscribe for real-time updates
      _messageSubscriptions[chatId] = _firestore
          .collection('chatMessages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        print(
            "ChatProvider.refreshMessages - Received update with ${snapshot.docs.length} messages");

        _chatMessages[chatId] = snapshot.docs
            .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
            .toList();

        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      print("ChatProvider.refreshMessages - ERROR: $e");
      _setError('Error refreshing messages: $e');
    }
  }

  // Public method to clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
