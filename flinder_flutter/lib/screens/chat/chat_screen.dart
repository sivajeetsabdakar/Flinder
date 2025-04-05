import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_bar_with_logout.dart';
import '../../providers/chat_context.dart';
import '../../models/chat_thread.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat/chat_thread_item.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final user = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUserId = user?.id;
        });
      }

      // Load conversations and subscribe to updates
      if (mounted && _currentUserId != null) {
        final chatContext = Provider.of<ChatContext>(context, listen: false);

        // For debugging: manually set the user ID to ensure it's available
        chatContext.setManualUserId(_currentUserId!);

        // Now load threads and subscribe
        await chatContext.loadChatThreads();
        chatContext.subscribeToThreads();
      } else {
        print('ChatScreen: No current user ID available - cannot load chats');
      }
    } catch (e) {
      // Handle error silently
      debugPrint('Error initializing chat screen: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithLogout(
        title: 'Chats',
        additionalActions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ChatContext>().loadChatThreads();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatDialog,
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentUserId == null) {
      return _buildErrorScreen('Not authenticated. Please sign in again.');
    }

    return Consumer<ChatContext>(
      builder: (context, chatContext, child) {
        if (chatContext.isLoadingThreads) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chatContext.threadsError != null) {
          return _buildErrorScreen(chatContext.threadsError!);
        }

        if (chatContext.threads.isEmpty) {
          return _buildEmptyScreen();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80), // Space for FAB
          itemCount: chatContext.threads.length,
          itemBuilder: (context, index) {
            final thread = chatContext.threads[index];
            return ChatThreadItem(
              thread: thread,
              currentUserId: _currentUserId!,
              onTap: () => _navigateToChatDetail(thread),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorScreen(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<ChatContext>().loadChatThreads();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppTheme.primaryPurple.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Messages Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Match with potential flatmates to start chatting!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showNewChatDialog,
              icon: const Icon(Icons.add),
              label: const Text('Start a New Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChatDetail(ChatThread thread) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatDetailScreen(chatId: thread.id, thread: thread),
      ),
    );
  }

  void _showNewChatDialog() {
    // This is a placeholder - in a real app, you'd show a dialog or screen
    // to select users to chat with or create a group
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Start a New Chat'),
            content: const Text(
              'This feature will allow you to select users to chat with. '
              'It will be implemented in a future update.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
