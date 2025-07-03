// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/sidebar.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import 'chat_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  late ChatProvider _chatProvider;
  late AuthProvider _authProvider;
  ChatModel? _selectedChat;
  bool _showNewChatDialog = false;
  String _chatType = 'customer'; // Default to customer chats
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String> _userNameCache = {};

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize chats for the current user
      if (_authProvider.isAuthenticated && _authProvider.userData != null) {
        _chatProvider.initChats(_authProvider.userData!.id);
      }
    });
  }

  // Helper method to create a new chat
  Future<void> _createNewChat(UserModel recipient, String chatType) async {
    if (_authProvider.userData == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authProvider.userData!.id;
      final recipientId = recipient.id;

      print("Creating chat with user: ${recipient.name} (ID: $recipientId)");

      // First check if chat already exists between these users
      ChatModel? existingChat;
      for (var chat in _chatProvider.chats) {
        if (chat.chatType == chatType &&
            chat.participants.contains(userId) &&
            chat.participants.contains(recipientId) &&
            chat.participants.length == 2) {
          existingChat = chat;
          break;
        }
      }

      if (existingChat != null) {
        print("Chat already exists, selecting existing chat");
        setState(() {
          _selectedChat = existingChat;
          _showNewChatDialog = false;
          _isLoading = false;
        });
        return;
      }

      // Create new chat without initial message
      final chatId = await _chatProvider.createChat(
        currentUserId: userId,
        participantIds: [recipientId, userId],
        chatType: chatType,
        initialMessage: null, // No initial message
      );

      if (chatId != null) {
        print("Chat created with ID: $chatId");

        // Wait briefly for Firebase to update
        await Future.delayed(const Duration(seconds: 1));

        // Manually fetch the new chat
        final chatDoc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .get();

        if (chatDoc.exists) {
          final newChat = ChatModel.fromMap(chatDoc.data()!, chatDoc.id);

          setState(() {
            _selectedChat = newChat;
            _showNewChatDialog = false;
          });
        } else {
          print("Created chat document not found: $chatId");
        }
      } else {
        print("Failed to create chat - null chatId returned");
      }
    } catch (e) {
      print("Error creating chat: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Create a test/dummy user for development purposes
  UserModel _createDummyUser(String chatType) {
    return UserModel.fromJson({
      'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
      'name': chatType == 'manager' ? 'Test Manager' : 'Test Customer',
      'email': 'test${chatType}@example.com',
      'role': chatType == 'manager' ? 'manager' : 'customer',
      'isActive': true,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    });
  }

  // Create a test chat with a dummy user
  void _createTestChat() {
    setState(() {
      _isLoading = true;
    });

    // Create a test user
    final testUser = _createDummyUser(_chatType);

    // Create a chat with this test user
    _createNewChat(testUser, _chatType);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Scaffold(
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Row(
            children: [
              // Sidebar
              Sidebar(
                selectedIndex: 10, // Chat index, update this in sidebar
                onItemSelected: (index) {
                  // Handle navigation if needed
                },
              ),

              // Chat list and content
              Expanded(
                child: Column(
                  children: [
                    // App bar
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Chats',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const Spacer(),

                          // Filter dropdown
                          DropdownButton<String>(
                            value: _chatType,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: 'customer',
                                child: Text('Customer Chats'),
                              ),
                              DropdownMenuItem(
                                value: 'manager',
                                child: Text('Manager Chats'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _chatType = value;
                                });
                              }
                            },
                          ),

                          const SizedBox(width: 16),

                          // New chat button
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('New Chat'),
                            onPressed: () {
                              setState(() {
                                _showNewChatDialog = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.borderColor),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),

                    // Chat content area
                    Expanded(
                      child: Row(
                        children: [
                          // Chat list
                          SizedBox(
                            width: 280,
                            child: _buildChatList(chatProvider),
                          ),

                          // Divider
                          Container(
                            width: 1,
                            color: AppColors.borderColor,
                          ),

                          // Chat content area
                          Expanded(
                            child: _selectedChat != null
                                ? ChatDetailScreen(
                                    chat: _selectedChat!,
                                    onBackPressed: () {
                                      setState(() {
                                        _selectedChat = null;
                                      });
                                    },
                                    onDeleteChat: () async {
                                      await _deleteChat(_selectedChat!.id);
                                      setState(() {
                                        _selectedChat = null;
                                      });
                                    },
                                  )
                                : _buildEmptyState(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      // Show recipient selection dialog
      bottomSheet: _showNewChatDialog ? _buildNewChatSheet() : null,
    );
  }

  // Chat list widget
  Widget _buildChatList(ChatProvider chatProvider) {
    if (chatProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (chatProvider.chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new conversation with the + button',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // Filter chats by type
    final filteredChats =
        chatProvider.chats.where((chat) => chat.chatType == _chatType).toList();

    // Show empty state if no chats of this type
    if (filteredChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_chatType.capitalize()} chats',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new chat with the "New Chat" button',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: filteredChats.length,
            itemBuilder: (context, index) {
              final chat = filteredChats[index];
              final userId = _authProvider.userData?.id ?? '';
              final unreadCount = chat.unreadCount[userId] ?? 0;

              // Get the other participant's ID (assuming 1-1 chat)
              String otherParticipantId = 'Unknown';
              if (chat.participants.length == 2) {
                otherParticipantId = chat.participants.firstWhere(
                  (id) => id != userId,
                  orElse: () => 'Unknown',
                );
              }

              // Look up or cache participant name
              _lookupUserName(otherParticipantId);
              final participantName =
                  _userNameCache[otherParticipantId] ?? otherParticipantId;

              // Filter by search query if any
              if (_searchQuery.isNotEmpty &&
                  !participantName.toLowerCase().contains(_searchQuery)) {
                return const SizedBox.shrink();
              }

              final formattedDate =
                  DateFormat.MMMd().format(chat.lastMessageTimestamp);

              return Dismissible(
                key: Key(chat.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Chat'),
                          content: const Text(
                              'Are you sure you want to delete this conversation?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (direction) {
                  _deleteChat(chat.id);
                },
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                    child: Text(
                      participantName.isNotEmpty
                          ? participantName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    participantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    chat.lastMessage.isEmpty
                        ? 'Start a conversation'
                        : chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  selected: _selectedChat?.id == chat.id,
                  selectedTileColor: AppColors.primaryColor.withOpacity(0.1),
                  onTap: () {
                    setState(() {
                      _selectedChat = chat;
                    });

                    // Mark as read when selected
                    if (unreadCount > 0) {
                      chatProvider.markChatAsRead(chat.id, userId);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Empty state when no chat is selected
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          const Text(
            'Select a chat to view messages',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Choose a conversation from the list or start a new chat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New chat recipient selection bottom sheet
  Widget _buildNewChatSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderColor,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'New Chat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _showNewChatDialog = false;
                          });
                        },
                ),
              ],
            ),
          ),

          // Chat type selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Chat with: '),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Customers'),
                  selected: _chatType == 'customer',
                  onSelected: _isLoading
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() {
                              _chatType = 'customer';
                            });
                          }
                        },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Managers'),
                  selected: _chatType == 'manager',
                  onSelected: _isLoading
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() {
                              _chatType = 'manager';
                            });
                          }
                        },
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Creating chat...'),
                      ],
                    ),
                  )
                : FutureBuilder<List<UserModel>>(
                    future: _chatProvider.getUsersForChat(_chatType),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.errorColor,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {});
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final users = snapshot.data ?? [];

                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off,
                                color: Colors.grey.shade400,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ${_chatType}s found',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try selecting a different user type',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.add),
                                label: Text(
                                    'Create Test ${_chatType.capitalize()} Chat'),
                                onPressed: () => _createTestChat(),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primaryColor.withOpacity(0.2),
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            onTap: _isLoading
                                ? null
                                : () {
                                    _createNewChat(user, _chatType);
                                  },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Add method to delete a chat
  Future<void> _deleteChat(String chatId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Chat'),
              content: const Text(
                  'Are you sure you want to delete this chat? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Delete chat messages first
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chatMessages')
          .where('chatId', isEqualTo: chatId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the chat document
      batch.delete(FirebaseFirestore.instance.collection('chats').doc(chatId));

      // Commit the batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat deleted successfully')),
      );
    } catch (e) {
      print('Error deleting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting chat: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to look up and cache user names
  Future<void> _lookupUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _userNameCache[userId] = userData['name'] ?? 'Unknown User';
        });
      } else {
        setState(() {
          _userNameCache[userId] = 'Unknown User';
        });
      }
    } catch (e) {
      print('Error looking up user name: $e');
      setState(() {
        _userNameCache[userId] = 'Unknown User';
      });
    }
  }
}
