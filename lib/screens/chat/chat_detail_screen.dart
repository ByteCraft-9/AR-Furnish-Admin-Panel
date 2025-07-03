import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatModel chat;
  final VoidCallback onBackPressed;
  final VoidCallback onDeleteChat;

  const ChatDetailScreen({
    super.key,
    required this.chat,
    required this.onBackPressed,
    required this.onDeleteChat,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AuthProvider _authProvider;
  late ChatProvider _chatProvider;
  String _chatName = 'Chat';

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Set chat name - in a real app, you'd look up the user's name from their ID
    _setChatName();

    // Mark messages as read
    if (_authProvider.userData != null) {
      _chatProvider.markChatAsRead(widget.chat.id, _authProvider.userData!.id);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Set chat name based on the other participant (assuming 1-1 chat)
  void _setChatName() {
    final currentUserId = _authProvider.userData?.id ?? '';
    if (widget.chat.participants.length == 2) {
      final otherParticipantId = widget.chat.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => 'Unknown',
      );

      // In a real app, you'd look up the user's name using their ID
      // For now, we'll just use the ID
      setState(() {
        _chatName = otherParticipantId;
      });
    }
  }

  // Send a message
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty || _authProvider.userData == null) {
      print(
          "Cannot send message: ${message.isEmpty ? 'Empty message' : 'No user data'}");
      return;
    }

    print(
        "Sending message: '$message' in chat ${widget.chat.id} from user ${_authProvider.userData!.id}");

    try {
      _chatProvider.sendMessage(
        chatId: widget.chat.id,
        senderId: _authProvider.userData!.id,
        message: message,
      );

      print("Message sent successfully");

      _messageController.clear();

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're subscribed to this chat's messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_authProvider.userData != null &&
          (!_chatProvider.chatMessages.containsKey(widget.chat.id) ||
              _chatProvider.chatMessages[widget.chat.id]?.isEmpty == true)) {
        print(
            "ChatDetailScreen - Explicitly refreshing messages for chat ${widget.chat.id}");
        // Force a refresh of the chat messages
        _chatProvider.refreshMessages(widget.chat.id);
      }
    });

    return Column(
      children: [
        // Chat header
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
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBackPressed,
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                child: Text(
                  _chatName.isNotEmpty ? _chatName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chatName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Chat ${widget.chat.chatType.capitalize()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Show delete button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Chat'),
                      content: const Text(
                          'Are you sure you want to delete this conversation?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onDeleteChat();
                          },
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Delete chat',
              ),
              // Show debug button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _chatProvider.refreshMessages(widget.chat.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing messages...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                tooltip: 'Refresh messages',
              ),
            ],
          ),
        ),

        // Show errors if any
        if (_chatProvider.error != null)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _chatProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  onPressed: () {
                    _chatProvider.clearError();
                  },
                ),
              ],
            ),
          ),

        // Chat messages
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages =
                    chatProvider.chatMessages[widget.chat.id] ?? [];

                if (messages.isEmpty) {
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
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation by sending a message',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final currentUserId = _authProvider.userData?.id ?? '';

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    final timeFormat = DateFormat.jm();

                    return _buildMessageBubble(
                      message: message.message,
                      time: timeFormat.format(message.timestamp),
                      isMe: isMe,
                      isRead: message.isRead,
                    );
                  },
                );
              },
            ),
          ),
        ),

        // Message input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () {
                  // Handle attachment
                },
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                color: AppColors.primaryColor,
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build a message bubble
  Widget _buildMessageBubble({
    required String message,
    required String time,
    required bool isMe,
    required bool isRead,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                _chatName.isNotEmpty ? _chatName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message content
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isMe ? Colors.white : AppColors.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
