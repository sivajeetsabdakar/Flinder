import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../models/chat_thread.dart';
import '../../models/app_user.dart';
import '../../providers/chat_context.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final ChatThread? thread;

  const ChatDetailScreen({Key? key, required this.chatId, this.thread})
    : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Register a callback to scroll when new messages arrive
    Future.microtask(() {
      final chatContext = Provider.of<ChatContext>(context, listen: false);
      chatContext.setMessageAddedCallback(_scrollToBottom);
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final userModel = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUserId = userModel?.id;
        });
      }

      // Set current chat and load messages
      if (mounted) {
        context.read<ChatContext>().setCurrentChat(widget.chatId);
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading chat: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Remove the message callback before disposing
    if (mounted) {
      context.read<ChatContext>().removeMessageAddedCallback();
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _currentUserId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      await context.read<ChatContext>().sendMessage(
        chatId: widget.chatId,
        content: message,
      );

      // Clear the input field
      _messageController.clear();

      // Explicitly scroll to the bottom to see the new message
      // Use a slightly longer delay to ensure the message is added to the list
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  AppUser? _getOtherUser() {
    if (widget.thread == null || _currentUserId == null) return null;
    return widget.thread!.getOtherUser(_currentUserId!);
  }

  String _getTitle() {
    if (widget.thread == null) return 'Chat';

    // For group chats, use the group name
    if (widget.thread!.isGroup) {
      return widget.thread!.name ?? 'Group Chat';
    }

    // For 1:1 chats, use the other person's name or the thread name
    if (widget.thread!.name != null && widget.thread!.name!.isNotEmpty) {
      return widget.thread!.name!;
    }

    return 'Chat';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_getTitle()),
        elevation: 0,
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                () => context.read<ChatContext>().loadMessages(widget.chatId),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryPurple,
                  ),
                ),
              )
              : Column(
                children: [
                  // Messages list
                  Expanded(child: _buildMessagesList()),

                  // Message input
                  _buildMessageInput(),
                ],
              ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<ChatContext>(
      builder: (context, chatContext, child) {
        if (chatContext.isLoadingMessages) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
            ),
          );
        }

        if (chatContext.messagesError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading messages',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  chatContext.messagesError!,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => chatContext.loadMessages(widget.chatId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (chatContext.messages.isEmpty) {
          return Center(
            child: Text(
              'No messages yet. Start the conversation!',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        // Scroll to bottom after the initial load
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: chatContext.messages.length,
          // Messages are already sorted chronologically with oldest at top, newest at bottom
          itemBuilder: (context, index) {
            final message = chatContext.messages[index];
            final isMe = message.senderId == _currentUserId;
            return _buildMessageBubble(message, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryPurple,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryPurple : Colors.grey[800],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.grey[200],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.sentAt),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check, size: 12, color: Colors.white70),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Attachment button (placeholder for now)
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.grey[400]),
            onPressed: () {
              // TODO: Implement attachment functionality
            },
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          // Send button
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryPurple,
                ),
                child:
                    _isSending
                        ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
