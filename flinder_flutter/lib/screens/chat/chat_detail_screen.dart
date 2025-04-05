import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../models/chat_thread.dart';
import '../../models/app_user.dart';
import '../../providers/chat_context.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'create_group_screen.dart';

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
  bool _showCreateGroupWidget = false;
  String? _chatTitle;
  bool _isFetchingTitle = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchChatTitle();

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

  // Send a new message
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Clear input field right away for better UX
      _messageController.clear();

      // Make sure we have a current user ID
      if (_currentUserId == null) {
        final userModel = await AuthService.getCurrentUser();
        if (mounted) {
          setState(() {
            _currentUserId = userModel?.id;
          });
        }
      }

      // Send the message via ChatContext
      if (mounted && _currentUserId != null) {
        await context.read<ChatContext>().sendMessage(
          chatId: widget.chatId,
          content: message,
        );

        // Show the group creation prompt occasionally after sending a message
        // In a real app, you might want to have more sophisticated logic here
        if (!_showCreateGroupWidget &&
            widget.thread != null &&
            !widget.thread!.isGroup &&
            message.length > 10) {
          // Only show for longer messages
          setState(() {
            _showCreateGroupWidget = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }

    // Scroll to the bottom to see the new message
    _scrollToBottom();
  }

  AppUser? _getOtherUser() {
    if (widget.thread == null || _currentUserId == null) return null;
    return widget.thread!.getOtherUser(_currentUserId!);
  }

  // Fetch the other user's name or group name for the chat title
  Future<void> _fetchChatTitle() async {
    if (_isFetchingTitle) return;

    setState(() {
      _isFetchingTitle = true;
    });

    try {
      print(
        'ChatDetailScreen: Starting to fetch chat title for ${widget.chatId}',
      );
      // Get current user ID
      if (_currentUserId == null) {
        final userModel = await AuthService.getCurrentUser();
        if (mounted) {
          setState(() {
            _currentUserId = userModel?.id;
          });
        }
      }

      if (_currentUserId == null) {
        print('ChatDetailScreen: Cannot fetch title - no current user ID');
        return;
      }

      // For group chats, use the group name from the thread
      if (widget.thread != null && widget.thread!.isGroup) {
        if (widget.thread!.name != null && widget.thread!.name!.isNotEmpty) {
          setState(() {
            _chatTitle = widget.thread!.name;
            _isFetchingTitle = false;
          });
          print('ChatDetailScreen: Set group chat title to: $_chatTitle');
          return;
        }
      }

      // For 1:1 chats, get the other user's name from Supabase
      final chatContext = Provider.of<ChatContext>(context, listen: false);

      print(
        'ChatDetailScreen: Getting other user in chat with current user $_currentUserId',
      );

      final otherUserDetails = await chatContext.getOtherUserInChat(
        widget.chatId,
        _currentUserId!,
      );

      print('ChatDetailScreen: Other user details: $otherUserDetails');

      if (otherUserDetails != null && otherUserDetails['name'] != null) {
        final userName = otherUserDetails['name'] as String;
        if (mounted) {
          setState(() {
            _chatTitle = userName;
            _isFetchingTitle = false;
          });
          print('ChatDetailScreen: Set chat title to user name: $_chatTitle');
        }
      } else {
        // Fallback to thread name or "Chat"
        final defaultTitle = _getDefaultTitle();
        setState(() {
          _chatTitle = defaultTitle;
          _isFetchingTitle = false;
        });
        print('ChatDetailScreen: Fallback to default title: $_chatTitle');
      }
    } catch (e) {
      print('Error fetching chat title: $e');
      if (mounted) {
        final defaultTitle = _getDefaultTitle();
        setState(() {
          _chatTitle = defaultTitle;
          _isFetchingTitle = false;
        });
        print('ChatDetailScreen: Error fallback to default title: $_chatTitle');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Try to fetch the title again if it's not available
    if (_chatTitle == null || _chatTitle == 'Chat') {
      _fetchChatTitle();
    }
  }

  // Get default title from thread or fallback to "Chat"
  String _getDefaultTitle() {
    if (widget.thread == null) return 'Chat';

    // For group chats, use the group name
    if (widget.thread!.isGroup) {
      return widget.thread!.name ?? 'Group Chat';
    }

    // For 1:1 chats, use the other person's name
    final otherUser = _getOtherUser();
    if (otherUser != null) {
      return otherUser.name;
    }

    // Use the thread name if set
    if (widget.thread!.name != null && widget.thread!.name!.isNotEmpty) {
      return widget.thread!.name!;
    }

    return 'Chat';
  }

  String _getTitle() {
    // Try to fetch again if we still have "Chat" as the title
    if (_chatTitle == "Chat" && !_isFetchingTitle) {
      Future.microtask(() => _fetchChatTitle());
    }

    // If we've already fetched the title, use it
    if (_chatTitle != null) {
      return _chatTitle!;
    }

    // Otherwise use the default title while we're fetching
    return _getDefaultTitle();
  }

  // Create a group chat with current chat participant
  void _createGroupWithCurrentUser() {
    if (widget.thread == null || _currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create group at this time')),
      );
      return;
    }

    // If this is already a group chat, don't allow creating another group
    if (widget.thread!.isGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is already a group chat')),
      );
      return;
    }

    final chatContext = Provider.of<ChatContext>(context, listen: false);

    // For one-on-one chats, get the other user
    final otherUser = widget.thread!.getOtherUser(_currentUserId!);
    if (otherUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find the other user')),
      );
      return;
    }

    // Navigate to create group screen with the current participant pre-selected
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CreateGroupScreen(
              existingThreads: chatContext.threads,
              currentUserId: _currentUserId!,
              preselectedUsers: [otherUser],
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            _isFetchingTitle
                ? Row(
                  children: const [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.0,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text("Loading chat..."),
                  ],
                )
                : Text(_getTitle()),
        elevation: 0,
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                () => context.read<ChatContext>().loadMessages(widget.chatId),
          ),
          // Add group creation button only for non-group chats
          if (widget.thread != null && !widget.thread!.isGroup)
            IconButton(
              icon: const Icon(Icons.group_add),
              tooltip: 'Create group with this user',
              onPressed: _createGroupWithCurrentUser,
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
              : _buildChatBody(),
    );
  }

  Widget _buildChatBody() {
    return Column(
      children: [
        // Message list takes most of the space
        Expanded(
          child: Consumer<ChatContext>(
            builder: (context, chatContext, child) {
              if (chatContext.isLoadingMessages) {
                return const Center(child: CircularProgressIndicator());
              }

              if (chatContext.messagesError != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading messages: ${chatContext.messagesError}',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            () => chatContext.loadMessages(widget.chatId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final messages = chatContext.messages;

              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isCurrentUser = message.senderId == _currentUserId;

                  // Add the create group widget after the last message
                  if (index == messages.length - 1 && _showCreateGroupWidget) {
                    return Column(
                      children: [
                        _buildMessageBubble(message, isCurrentUser),
                        const SizedBox(height: 16),
                        _buildCreateGroupPrompt(),
                      ],
                    );
                  }

                  return _buildMessageBubble(message, isCurrentUser);
                },
              );
            },
          ),
        ),

        // Input area at the bottom
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppTheme.darkGrey,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
                onPressed: () {
                  // Attach files functionality would go here
                },
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) => setState(() {}),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.send_rounded,
                  color:
                      _messageController.text.trim().isNotEmpty
                          ? AppTheme.primaryPurple
                          : Colors.grey,
                ),
                onPressed:
                    _messageController.text.trim().isNotEmpty
                        ? () => _sendMessage()
                        : null,
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildCreateGroupPrompt() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Create a group chat?",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Start a group conversation with this person and others",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showCreateGroupWidget = false;
                  });
                },
                child: const Text("Not now"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _createGroupWithCurrentUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Create Group"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
