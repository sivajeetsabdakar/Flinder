import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../services/auth_service.dart';

// Import this from main.dart to check Supabase availability
import '../main.dart' show isSupabaseAvailable;

class ChatContext extends ChangeNotifier {
  // Supabase client reference
  SupabaseClient? _supabase;

  // Messages in current chat
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  // Available chat threads
  List<ChatThread> _threads = [];
  List<ChatThread> get threads => _threads;

  // Current active chat ID
  String? _currentChatId;
  String? get currentChatId => _currentChatId;

  // Loading states
  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  bool _isLoadingThreads = false;
  bool get isLoadingThreads => _isLoadingThreads;

  // Error states
  String? _messagesError;
  String? get messagesError => _messagesError;

  String? _threadsError;
  String? get threadsError => _threadsError;

  // Manual user ID for testing/debugging
  String? _manualUserId;

  // Callback for when new messages are added
  VoidCallback? _messageAddedCallback;

  // Subscriptions
  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _threadSubscription;

  // Initialize and get Supabase client safely
  SupabaseClient? _getSupabaseClient() {
    // If Supabase is globally disabled, don't try to get a client
    if (!isSupabaseAvailable) {
      return null;
    }

    try {
      if (_supabase == null) {
        if (Supabase.instance != null) {
          _supabase = Supabase.instance.client;
        }
      }
      return _supabase;
    } catch (e) {
      debugPrint('Supabase not initialized yet: $e');
      return null;
    }
  }

  // Set a user ID manually for testing/debugging purposes
  void setManualUserId(String userId) {
    _manualUserId = userId;
    print('ChatContext: Manually set user ID to $_manualUserId');

    // Reload data with the new user ID
    loadChatThreads();
    subscribeToThreads();
  }

  // Get current user ID from various sources
  Future<String?> _getCurrentUserId() async {
    // If we have a manual user ID set, use that first
    if (_manualUserId != null && _manualUserId!.isNotEmpty) {
      print('Using manually set user ID: $_manualUserId');
      return _manualUserId;
    }

    try {
      // First try to get the user ID from AuthService
      final userModel = await AuthService.getCurrentUser();
      if (userModel != null && userModel.id.isNotEmpty) {
        print('Using AuthService user ID: ${userModel.id}');
        return userModel.id;
      }

      // If Supabase is disabled, don't try to get user from there
      if (!isSupabaseAvailable) {
        print('Supabase is disabled, cannot get user ID from there');
        return null;
      }

      // If that fails, fall back to Supabase auth
      final client = _getSupabaseClient();
      if (client == null) return null;

      final supabaseUserId = client.auth.currentUser?.id;
      if (supabaseUserId != null) {
        print('Using Supabase user ID: $supabaseUserId');
        return supabaseUserId;
      }

      print('No user ID found from any source');
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Load messages for a specific chat directly from Supabase
  Future<void> loadMessages(String chatId) async {
    if (_isLoadingMessages) return;

    _isLoadingMessages = true;
    _messagesError = null;
    _currentChatId = chatId;
    notifyListeners();

    try {
      final client = _getSupabaseClient();
      final userId = await _getCurrentUserId();

      // Check if we have the prerequisites to load real data
      if (client == null || userId == null) {
        print('ChatContext: Unable to load real messages - using dummy data');
        _loadDummyMessages(chatId);
        return;
      }

      print('ChatContext: Loading messages for chat $chatId');

      final response = await client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('sent_at', ascending: true);

      _messages =
          (response as List<dynamic>)
              .map((data) => ChatMessage.fromJson(data))
              .toList();

      print('ChatContext: Loaded ${_messages.length} messages');
    } catch (e) {
      print('ChatContext: Error loading messages: $e');
      _messagesError = e.toString();

      // If we have a real error, load dummy data in debug mode
      if (_messages.isEmpty) {
        print('ChatContext: Using dummy messages as fallback');
        _loadDummyMessages(chatId);
      }
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // Load dummy messages for testing and when Supabase is not available
  void _loadDummyMessages(String chatId) {
    final currentTime = DateTime.now();
    final userId = _manualUserId ?? 'current-user-id';

    // Find the dummy chat by ID
    String chatName = 'Chat';
    for (var thread in _threads) {
      if (thread.id == chatId) {
        chatName = thread.name ?? 'Chat';
        break;
      }
    }

    // Create a dummy conversation based on the chat ID
    switch (chatId) {
      case '1': // Sarah Johnson
        _messages = [
          ChatMessage(
            id: '101',
            chatId: chatId,
            senderId: 'sarah-id',
            content:
                'Hi there! I saw your listing for the apartment on Flinder.',
            sentAt: currentTime.subtract(const Duration(days: 1, hours: 2)),
            isRead: true,
          ),
          ChatMessage(
            id: '102',
            chatId: chatId,
            senderId: userId,
            content:
                'Hey Sarah! Thanks for reaching out. What would you like to know about it?',
            sentAt: currentTime.subtract(
              const Duration(days: 1, hours: 1, minutes: 45),
            ),
            isRead: true,
          ),
          ChatMessage(
            id: '103',
            chatId: chatId,
            senderId: 'sarah-id',
            content:
                'I\'m wondering about the monthly rent and if utilities are included?',
            sentAt: currentTime.subtract(const Duration(days: 1, minutes: 30)),
            isRead: true,
          ),
          ChatMessage(
            id: '104',
            chatId: chatId,
            senderId: 'sarah-id',
            content: 'Also, is there a washer/dryer in the unit?',
            sentAt: currentTime.subtract(const Duration(minutes: 20)),
            isRead: false,
          ),
          ChatMessage(
            id: '105',
            chatId: chatId,
            senderId: 'sarah-id',
            content: 'I\'d love to schedule a viewing if possible!',
            sentAt: currentTime.subtract(const Duration(minutes: 5)),
            isRead: false,
          ),
        ];
        break;

      case '2': // Roommate Finder Group
        _messages = [
          ChatMessage(
            id: '201',
            chatId: chatId,
            senderId: 'alex-id',
            content:
                'Hi everyone! I\'m looking for a roommate in the downtown area.',
            sentAt: currentTime.subtract(const Duration(days: 2, hours: 3)),
            isRead: true,
          ),
          ChatMessage(
            id: '202',
            chatId: chatId,
            senderId: 'jamie-id',
            content: 'What\'s your budget? I\'m also looking downtown.',
            sentAt: currentTime.subtract(const Duration(days: 2, hours: 2)),
            isRead: true,
          ),
          ChatMessage(
            id: '203',
            chatId: chatId,
            senderId: userId,
            content:
                'I have a 2-bedroom near Central Park if anyone\'s interested?',
            sentAt: currentTime.subtract(const Duration(days: 1, hours: 5)),
            isRead: true,
          ),
          ChatMessage(
            id: '204',
            chatId: chatId,
            senderId: 'morgan-id',
            content: 'Anyone looking in Manhattan area?',
            sentAt: currentTime.subtract(const Duration(hours: 1)),
            isRead: true,
          ),
        ];
        break;

      default:
        // Generic conversation for other chats
        _messages = [
          ChatMessage(
            id: '901',
            chatId: chatId,
            senderId: 'other-user-id',
            content:
                'Hello! I\'m interested in finding out more about your listing.',
            sentAt: currentTime.subtract(const Duration(days: 1, hours: 3)),
            isRead: true,
          ),
          ChatMessage(
            id: '902',
            chatId: chatId,
            senderId: userId,
            content: 'Hi there! What would you like to know?',
            sentAt: currentTime.subtract(const Duration(days: 1, hours: 2)),
            isRead: true,
          ),
          ChatMessage(
            id: '903',
            chatId: chatId,
            senderId: 'other-user-id',
            content: 'Is it still available?',
            sentAt: currentTime.subtract(const Duration(hours: 5)),
            isRead: true,
          ),
        ];
    }

    print(
      'ChatContext: Loaded ${_messages.length} dummy messages for chat $chatId',
    );
  }

  // Subscribe to real-time message updates
  void subscribeToChat(String chatId) {
    // Cancel existing message subscription if any
    _messageSubscription?.cancel();

    // Get supabase client
    final client = _getSupabaseClient();
    if (client == null) {
      _messagesError = 'Supabase client not initialized';
      notifyListeners();
      return;
    }

    // Create new subscription
    _messageSubscription = client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('sent_at', ascending: true)
        .listen((List<Map<String, dynamic>> data) {
          _messages = data.map((e) => ChatMessage.fromJson(e)).toList();
          notifyListeners();

          // Auto-scroll to latest messages after update
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_messageAddedCallback != null) {
              _messageAddedCallback!();
            }
          });
        });
  }

  // Load available chat threads for the current user
  Future<void> loadChatThreads() async {
    if (_isLoadingThreads) return;

    _isLoadingThreads = true;
    _threadsError = null;
    notifyListeners();

    try {
      final client = _getSupabaseClient();
      final userId = await _getCurrentUserId();

      // Check if we have the prerequisites to load real data
      if (client == null || userId == null) {
        print('ChatContext: Unable to load real threads - using dummy data');
        _loadDummyThreads();
        return;
      }

      print('ChatContext: Loading threads for user $userId');

      // First get all chat IDs that the user is part of
      final chatMembersResponse = await client
          .from('chat_members')
          .select('chat_id')
          .eq('user_id', userId);

      if (chatMembersResponse == null) {
        throw Exception('Failed to load chat memberships');
      }

      final chatIds =
          (chatMembersResponse as List<dynamic>)
              .map((item) => item['chat_id'] as String)
              .toList();

      if (chatIds.isEmpty) {
        print('ChatContext: No chat memberships found');
        _threads = [];
        _isLoadingThreads = false;
        notifyListeners();
        return;
      }

      print('ChatContext: Found ${chatIds.length} chat memberships');

      // Now get chat details for each chat ID - use eq for each ID since in_ may not be available
      List<ChatThread> tempThreads = [];

      for (String chatId in chatIds) {
        print('ChatContext: Loading chat details for $chatId');
        final chatResponse =
            await client.from('chats').select().eq('id', chatId).single();

        if (chatResponse != null) {
          // Get latest message
          final messagesResponse = await client
              .from('messages')
              .select()
              .eq('chat_id', chatId)
              .order('sent_at', ascending: false)
              .limit(1);

          String lastMessage = '';
          DateTime? lastMessageTime;

          if (messagesResponse != null &&
              (messagesResponse as List).isNotEmpty) {
            lastMessage = messagesResponse[0]['content'] ?? '';
            lastMessageTime = DateTime.parse(messagesResponse[0]['sent_at']);
          }

          // For now we'll skip unread count since there's no is_read column
          int unreadCount = 0;

          // Create thread object
          tempThreads.add(
            ChatThread(
              id: chatId,
              name: chatResponse['name'] ?? 'Chat',
              isGroup: chatResponse['is_group'] ?? false,
              lastMessage: lastMessage,
              lastMessageTime: lastMessageTime,
              unreadCount: unreadCount,
            ),
          );
        }
      }

      // Sort threads by last message time (most recent first)
      tempThreads.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      _threads = tempThreads;
      print('ChatContext: Loaded ${_threads.length} threads successfully');
    } catch (e) {
      print('ChatContext: Error loading threads: $e');
      _threadsError = e.toString();

      // If we have a real error, load dummy data in debug mode
      if (_threads.isEmpty) {
        print('ChatContext: Using dummy data as fallback');
        _loadDummyThreads();
      }
    } finally {
      _isLoadingThreads = false;
      notifyListeners();
    }
  }

  // Load dummy threads for testing and when Supabase is not available
  void _loadDummyThreads() {
    final currentTime = DateTime.now();

    _threads = [
      ChatThread(
        id: '1',
        name: 'Sarah Johnson',
        isGroup: false,
        lastMessage: 'Hey! I\'m interested in the apartment you posted.',
        lastMessageTime: currentTime.subtract(const Duration(minutes: 5)),
        unreadCount: 2,
      ),
      ChatThread(
        id: '2',
        name: 'Roommate Finder Group',
        isGroup: true,
        lastMessage: 'Anyone looking in Manhattan area?',
        lastMessageTime: currentTime.subtract(const Duration(hours: 1)),
        unreadCount: 0,
      ),
      ChatThread(
        id: '3',
        name: 'John Smith',
        isGroup: false,
        lastMessage: 'What\'s the earliest move-in date?',
        lastMessageTime: currentTime.subtract(const Duration(hours: 4)),
        unreadCount: 0,
      ),
      ChatThread(
        id: '4',
        name: 'Alex Wong',
        isGroup: false,
        lastMessage: 'Is the apartment pet-friendly?',
        lastMessageTime: currentTime.subtract(const Duration(days: 1)),
        unreadCount: 0,
      ),
    ];

    print('ChatContext: Loaded ${_threads.length} dummy threads');
  }

  // Subscribe to real-time thread updates
  void subscribeToThreads() async {
    // Cancel existing thread subscription if any
    _threadSubscription?.cancel();

    // Get supabase client
    final client = _getSupabaseClient();
    if (client == null) {
      _threadsError = 'Supabase client not initialized';
      notifyListeners();
      return;
    }

    final userId = await _getCurrentUserId();
    if (userId == null) {
      _threadsError = 'User not authenticated';
      notifyListeners();
      return;
    }

    // Create new subscription to chat_members to know when user is added to chats
    _threadSubscription = client
        .from('chat_members')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((_) {
          // When chat memberships change, reload threads
          loadChatThreads();
        });

    // Also subscribe to all messages to update the last message in threads
    client.from('messages').stream(primaryKey: ['id']).listen((_) {
      // When new messages arrive, reload threads to update last message
      loadChatThreads();
    });
  }

  // Send a message via Supabase
  Future<void> sendMessage({
    required String chatId,
    required String content,
    String? attachment,
    String? attachmentType,
  }) async {
    final client = _getSupabaseClient();
    final userId = await _getCurrentUserId();

    // Verify we have a user ID at minimum
    if (userId == null) {
      throw Exception('User not authenticated - cannot send message');
    }

    try {
      // Generate a local UUID-like ID for the message
      final localMessageId =
          'local-${DateTime.now().millisecondsSinceEpoch}-${_messages.length}';
      final timestamp = DateTime.now();

      // Create the message object
      final message = ChatMessage(
        id: localMessageId,
        chatId: chatId,
        senderId: userId,
        content: content,
        sentAt: timestamp,
        isRead: false,
        attachment: attachment,
        attachmentType: attachmentType,
      );

      // Add message to the local list immediately for UI responsiveness
      _messages.add(message);
      notifyListeners();

      print('ChatContext: Added message to local list: $content');

      // If we have a Supabase client, try to send the message to the server
      if (client != null) {
        print('ChatContext: Sending message to Supabase');

        await client.from('messages').insert({
          'chat_id': chatId,
          'sender_id': userId,
          'content': content,
          'sent_at': timestamp.toIso8601String(),
          if (attachment != null) 'attachment': attachment,
          if (attachmentType != null) 'attachment_type': attachmentType,
        });

        print('ChatContext: Message sent to Supabase successfully');
      } else {
        print(
          'ChatContext: Working in offline mode, message saved locally only',
        );
      }

      // Update the corresponding thread with the new message info
      _updateThreadWithLastMessage(chatId, content, timestamp);
    } catch (e) {
      print('ChatContext: Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Update a thread with the latest message info
  void _updateThreadWithLastMessage(
    String chatId,
    String content,
    DateTime timestamp,
  ) {
    final threadIndex = _threads.indexWhere((thread) => thread.id == chatId);
    if (threadIndex != -1) {
      // Create a copy of the thread with updated last message info
      final updatedThread = ChatThread(
        id: _threads[threadIndex].id,
        name: _threads[threadIndex].name,
        isGroup: _threads[threadIndex].isGroup,
        lastMessage: content,
        lastMessageTime: timestamp,
        unreadCount: _threads[threadIndex].unreadCount,
      );

      // Replace the thread in the list
      _threads[threadIndex] = updatedThread;

      // Move this thread to the top of the list (most recent)
      if (threadIndex > 0) {
        final thread = _threads.removeAt(threadIndex);
        _threads.insert(0, thread);
      }

      notifyListeners();
      print('ChatContext: Updated thread with last message');
    }
  }

  // Create a new chat thread
  Future<String> createChatThread({
    required List<String> memberIds,
    required bool isGroup,
    String? name,
  }) async {
    final client = _getSupabaseClient();
    if (client == null) {
      throw Exception('Supabase client not initialized');
    }

    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Make sure current user is included in members
    if (!memberIds.contains(userId)) {
      memberIds.add(userId);
    }

    try {
      // Create a new chat
      final chatResponse =
          await client.from('chats').insert({
            'is_group': isGroup,
            'name': name ?? (isGroup ? 'Group Chat' : null),
            'created_by': userId,
            'created_at': DateTime.now().toIso8601String(),
          }).select();

      if (chatResponse == null || (chatResponse as List).isEmpty) {
        throw Exception('Failed to create chat');
      }

      final chatId = chatResponse[0]['id'] as String;

      // Add members to the chat
      final membersData =
          memberIds
              .map(
                (memberId) => {
                  'chat_id': chatId,
                  'user_id': memberId,
                  'joined_at': DateTime.now().toIso8601String(),
                },
              )
              .toList();

      await client.from('chat_members').insert(membersData);

      return chatId;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Mark messages as read - No-op since there's no is_read column
  Future<void> markAsRead(String chatId) async {
    // This function is a no-op now since we don't have an is_read column
    // We keep it to maintain API compatibility
    return;
  }

  // Set current chat and load its messages
  void setCurrentChat(String chatId) {
    if (_currentChatId != chatId) {
      _currentChatId = chatId;
      loadMessages(chatId);
      subscribeToChat(chatId);
      markAsRead(chatId); // This is a no-op now but we keep the call
    }
  }

  // Initialize ChatContext
  Future<void> initialize() async {
    print('ChatContext: Initializing...');

    try {
      // First check if Supabase is available globally
      if (!isSupabaseAvailable) {
        print(
          'ChatContext: Supabase is disabled globally, will work in offline mode',
        );

        // Auto-load dummy data for better UX in offline mode
        _loadDummyThreads();
        return;
      }

      // Check if Supabase client is available
      if (_getSupabaseClient() == null) {
        print(
          'ChatContext: Supabase client not available yet, will work in offline mode',
        );
      } else {
        print('ChatContext: Supabase client available');
      }

      // Get user ID
      final userId = await _getCurrentUserId();
      if (userId == null) {
        print(
          'ChatContext: No user ID available - will use user ID when provided',
        );
        return;
      }

      print('ChatContext: Found user ID $userId');
      loadChatThreads();
      subscribeToThreads();
    } catch (e) {
      print('ChatContext: Error during initialization: $e');
      // Continue without failing - we'll retry operations when needed
    }
  }

  // Clean up resources when no longer needed
  @override
  void dispose() {
    _messageSubscription?.cancel();
    _threadSubscription?.cancel();
    super.dispose();
  }

  // Set a callback to be called when new messages are added
  void setMessageAddedCallback(VoidCallback callback) {
    _messageAddedCallback = callback;
  }

  // Remove the message added callback
  void removeMessageAddedCallback() {
    _messageAddedCallback = null;
  }

  // Create a new group chat and add members
  Future<String?> createGroupChat(
    String groupName,
    List<String> memberIds,
  ) async {
    try {
      final client = _getSupabaseClient();
      final userId = await _getCurrentUserId();

      if (client == null || userId == null) {
        print(
          'ChatContext: Cannot create group chat - client or userId is null',
        );
        return null;
      }

      print(
        'ChatContext: Creating group chat "$groupName" with ${memberIds.length} members',
      );

      // 1. Create a new chat entry
      final chatInsertRes =
          await client
              .from('chats')
              .insert({'name': groupName, 'is_group': true})
              .select('id')
              .single();

      if (chatInsertRes == null || chatInsertRes['id'] == null) {
        throw Exception('Failed to create chat');
      }

      final chatId = chatInsertRes['id'] as String;
      print('ChatContext: Created chat with ID: $chatId');

      // 2. Add all the members to the chat
      final membersToInsert =
          memberIds
              .map((userId) => {'chat_id': chatId, 'user_id': userId})
              .toList();

      await client.from('chat_members').insert(membersToInsert);
      print('ChatContext: Added ${memberIds.length} members to chat $chatId');

      // 3. Add a system message about group creation
      await client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': userId,
        'content': 'Group "$groupName" created',
        'is_system_message': true,
      });

      // 4. Reload threads to include the new group
      await loadChatThreads();

      return chatId;
    } catch (e) {
      print('ChatContext: Error creating group chat: $e');
      return null;
    }
  }

  // Create a chat between two users when they match and send the first message
  Future<String?> createMatchChat(
    String otherUserId,
    String otherUserName,
  ) async {
    try {
      final client = _getSupabaseClient();
      final currentUserId = await _getCurrentUserId();

      if (client == null || currentUserId == null) {
        print(
          'ChatContext: Cannot create match chat - client or userId is null',
        );
        return null;
      }

      print(
        'ChatContext: Creating match chat between $currentUserId and $otherUserId',
      );

      // 1. Create a new chat entry (not a group)
      final chatInsertRes =
          await client
              .from('chats')
              .insert({
                'is_group': false,
                'created_at': DateTime.now().toIso8601String(),
              })
              .select('id')
              .single();

      if (chatInsertRes == null || chatInsertRes['id'] == null) {
        throw Exception('Failed to create chat');
      }

      final chatId = chatInsertRes['id'] as String;
      print('ChatContext: Created match chat with ID: $chatId');

      // 2. Add both users to the chat
      final membersToInsert = [
        {'chat_id': chatId, 'user_id': currentUserId},
        {'chat_id': chatId, 'user_id': otherUserId},
      ];

      await client.from('chat_members').insert(membersToInsert);
      print('ChatContext: Added both users to chat $chatId');

      // 3. Send welcome message from current user
      final welcomeMessage = "Hello, it's great connecting with you!";
      await client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': currentUserId,
        'content': welcomeMessage,
        'sent_at': DateTime.now().toIso8601String(),
      });
      print('ChatContext: Sent welcome message to chat $chatId');

      // 4. Reload threads to include the new chat
      await loadChatThreads();

      return chatId;
    } catch (e) {
      print('ChatContext: Error creating match chat: $e');
      return null;
    }
  }

  // Get a list of users who have active chats with the current user
  Future<List<dynamic>> getUsersWithActiveChats() async {
    final client = _getSupabaseClient();
    final userId = await _getCurrentUserId();

    if (client == null || userId == null) {
      return [];
    }

    try {
      // Get all chats the current user is a member of
      final chatMembersResponse = await client
          .from('chat_members')
          .select('chat_id')
          .eq('user_id', userId);

      if (chatMembersResponse == null ||
          (chatMembersResponse as List).isEmpty) {
        return [];
      }

      // Extract chat IDs
      final chatIds =
          (chatMembersResponse as List)
              .map((item) => item['chat_id'] as String)
              .toList();

      if (chatIds.isEmpty) {
        return [];
      }

      // Get all members of these chats excluding the current user
      final List<dynamic> otherMembers = [];

      // Fetch members for each chat separately since we can't use in_
      for (final chatId in chatIds) {
        final chatMembersResult = await client
            .from('chat_members')
            .select(
              'user_id, users!inner(id, email, name, profile_picture_url)',
            )
            .eq('chat_id', chatId)
            .neq('user_id', userId);

        if (chatMembersResult != null &&
            (chatMembersResult as List).isNotEmpty) {
          otherMembers.addAll(chatMembersResult);
        }
      }

      if (otherMembers.isEmpty) {
        return [];
      }

      // Extract unique users
      final Set<String> uniqueUserIds = {};
      final List<dynamic> uniqueUsers = [];

      for (var member in otherMembers) {
        final userData = member['users'];
        final userId = userData['id'] as String;

        if (!uniqueUserIds.contains(userId)) {
          uniqueUserIds.add(userId);
          uniqueUsers.add({
            'id': userId,
            'name': userData['name'] ?? 'Unknown User',
            'email': userData['email'] ?? '',
            'profilePic': userData['profile_picture_url'],
          });
        }
      }

      return uniqueUsers;
    } catch (e) {
      print('ChatContext: Error getting users with active chats: $e');
      return [];
    }
  }

  // Get user details by user ID for displaying in chat
  Future<Map<String, dynamic>?> getUserDetailsById(String userId) async {
    try {
      final client = _getSupabaseClient();
      if (client == null) {
        print('ChatContext: Cannot get user details - client is null');
        return null;
      }

      // Fetch user data from the users table
      final response =
          await client
              .from('users')
              .select('id, name, email, profile_picture_url')
              .eq('id', userId)
              .single();

      if (response != null) {
        print('ChatContext: Found user details for ID: $userId');
        return response;
      } else {
        print('ChatContext: No user details found for ID: $userId');
        return null;
      }
    } catch (e) {
      print('ChatContext: Error fetching user details: $e');
      return null;
    }
  }

  // Get other user details from a one-on-one chat
  Future<Map<String, dynamic>?> getOtherUserInChat(
    String chatId,
    String currentUserId,
  ) async {
    try {
      print(
        'ChatContext: Getting other user in chat $chatId for current user $currentUserId',
      );

      final client = _getSupabaseClient();
      if (client == null) {
        print('ChatContext: Cannot get chat members - client is null');
        return null;
      }

      // First check if this is a 1:1 chat (not a group)
      try {
        final chatResponse =
            await client
                .from('chats')
                .select('is_group')
                .eq('id', chatId)
                .single();

        print('ChatContext: Chat data: $chatResponse');

        if (chatResponse == null || chatResponse['is_group'] == true) {
          print(
            'ChatContext: Chat is a group or not found, cannot get other user',
          );
          return null;
        }

        // Get all members of this chat
        final membersResponse = await client
            .from('chat_members')
            .select('user_id')
            .eq('chat_id', chatId);

        print('ChatContext: Chat members: $membersResponse');

        if (membersResponse == null || (membersResponse as List).isEmpty) {
          print('ChatContext: No members found for chat: $chatId');
          return null;
        }

        // Find the member that is not the current user
        String? otherUserId;
        for (var member in membersResponse) {
          final memberId = member['user_id'] as String;
          print(
            'ChatContext: Checking member: $memberId vs current: $currentUserId',
          );

          if (memberId != currentUserId) {
            otherUserId = memberId;
            print('ChatContext: Found other user: $otherUserId');
            break;
          }
        }

        if (otherUserId == null) {
          print('ChatContext: Could not find other user in chat: $chatId');
          return null;
        }

        // Get user details - try a direct query first
        try {
          final userResponse =
              await client
                  .from('users')
                  .select('id, name, email, profile_picture_url')
                  .eq('id', otherUserId)
                  .maybeSingle();

          print('ChatContext: Found user details: $userResponse');

          if (userResponse != null) {
            return userResponse;
          }
        } catch (userError) {
          print(
            'ChatContext: Error getting user details: $userError, trying fallback',
          );
        }

        // Fallback to our helper method
        final userDetails = await getUserDetailsById(otherUserId);
        print('ChatContext: User details from fallback: $userDetails');
        return userDetails;
      } catch (chatError) {
        print('ChatContext: Error getting chat details: $chatError');
        return null;
      }
    } catch (e) {
      print('ChatContext: Error getting other user in chat: $e');
      return null;
    }
  }
}
