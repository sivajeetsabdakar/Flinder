import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../services/auth_service.dart';

class ChatContext extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  List<ChatThread> _threads = [];
  List<ChatThread> get threads => _threads;

  String? _currentChatId;
  String? get currentChatId => _currentChatId;

  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  bool _isLoadingThreads = false;
  bool get isLoadingThreads => _isLoadingThreads;

  String? _messagesError;
  String? get messagesError => _messagesError;

  String? _threadsError;
  String? get threadsError => _threadsError;

  String? _manualUserId;
  VoidCallback? _messageAddedCallback;
  WebSocketChannel? _chatChannel;

  void setManualUserId(String userId) {
    _manualUserId = userId;
    loadChatThreads();
  }

  Future<String?> _getCurrentUserId() async {
    if (_manualUserId != null && _manualUserId!.isNotEmpty) {
      return _manualUserId;
    }

    final userModel = await AuthService.getCurrentUser();
    return userModel?.id;
  }

  Future<Map<String, String>?> _headers({bool includeJson = false}) async {
    final token = await AuthService.getAuthToken();
    if (token == null) return null;

    return {
      if (includeJson) 'Content-Type': 'application/json',
      'Authorization': token,
    };
  }

  Future<void> loadMessages(String chatId) async {
    if (_isLoadingMessages) return;

    _isLoadingMessages = true;
    _messagesError = null;
    _currentChatId = chatId;
    notifyListeners();

    try {
      final headers = await _headers();
      if (headers == null) {
        if (ApiConstants.allowDummyFallback) _loadDummyMessages(chatId);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/conversations/$chatId/messages'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load messages: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final messages = data['messages'] as List? ?? [];
      _messages =
          messages
              .map(
                (item) => ChatMessage.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();
    } catch (e) {
      _messagesError = e.toString();
      if (_messages.isEmpty && ApiConstants.allowDummyFallback) {
        _loadDummyMessages(chatId);
      }
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  void _loadDummyMessages(String chatId) {
    final currentTime = DateTime.now();
    final userId = _manualUserId ?? 'current-user-id';
    _messages = [
      ChatMessage(
        id: '901',
        chatId: chatId,
        senderId: 'other-user-id',
        content: 'Hello! I am interested in finding out more.',
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
    ];
  }

  Future<void> subscribeToChat(String chatId) async {
    await _chatChannel?.sink.close();
    final token = await AuthService.getAuthToken();
    if (token == null) return;
    final base =
        ApiConstants.baseUrl.isEmpty
            ? Uri.base
            : Uri.parse(ApiConstants.baseUrl);
    final uri = Uri(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/api/conversations/$chatId/ws',
      queryParameters: {'token': token},
    );
    _chatChannel = WebSocketChannel.connect(uri);
    _chatChannel!.stream.listen(
      (event) {
        final data = jsonDecode(event as String) as Map<String, dynamic>;
        if (data['type'] == 'message' && data['message'] is Map) {
          final message = ChatMessage.fromJson(
            Map<String, dynamic>.from(data['message'] as Map),
          );
          if (!_messages.any((item) => item.id == message.id)) {
            _messages.add(message);
            _updateThreadWithLastMessage(
              chatId,
              message.content,
              message.sentAt,
            );
            _messageAddedCallback?.call();
            notifyListeners();
          }
        }
      },
      onError: (_) {},
      onDone: () {},
    );
  }

  Future<void> loadChatThreads() async {
    if (_isLoadingThreads) return;

    _isLoadingThreads = true;
    _threadsError = null;
    notifyListeners();

    try {
      final headers = await _headers();
      if (headers == null) {
        if (ApiConstants.allowDummyFallback) _loadDummyThreads();
        return;
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.conversationsEndpoint}',
        ),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load conversations: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final conversations = data['conversations'] as List? ?? [];
      _threads =
          conversations
              .map(
                (item) =>
                    ChatThread.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
    } catch (e) {
      _threadsError = e.toString();
      if (_threads.isEmpty && ApiConstants.allowDummyFallback) {
        _loadDummyThreads();
      }
    } finally {
      _isLoadingThreads = false;
      notifyListeners();
    }
  }

  void _loadDummyThreads() {
    final currentTime = DateTime.now();
    _threads = [
      ChatThread(
        id: '1',
        name: 'Sarah Johnson',
        isGroup: false,
        lastMessage: 'Hey! I am interested in the apartment you posted.',
        lastMessageTime: currentTime.subtract(const Duration(minutes: 5)),
        unreadCount: 2,
      ),
      ChatThread(
        id: '2',
        name: 'Roommate Finder Group',
        isGroup: true,
        lastMessage: 'Anyone looking in Gandhinagar?',
        lastMessageTime: currentTime.subtract(const Duration(hours: 1)),
        unreadCount: 0,
      ),
    ];
  }

  void subscribeToThreads() {}

  Future<void> sendMessage({
    required String chatId,
    required String content,
    String? attachment,
    String? attachmentType,
  }) async {
    final userId = await _getCurrentUserId();
    if (userId == null) throw Exception('User not authenticated');

    final timestamp = DateTime.now();
    final message = ChatMessage(
      id: 'local-${timestamp.millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: userId,
      content: content,
      sentAt: timestamp,
      attachment: attachment,
      attachmentType: attachmentType,
    );

    _messages.add(message);
    _updateThreadWithLastMessage(chatId, content, timestamp);
    notifyListeners();

    final headers = await _headers(includeJson: true);
    if (headers == null) return;

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/conversations/$chatId/messages'),
      headers: headers,
      body: jsonEncode({
        'content': content,
        if (attachment != null) 'attachment': attachment,
        if (attachmentType != null) 'attachmentType': attachmentType,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      _messages.removeWhere((item) => item.id == message.id);
      notifyListeners();
      throw Exception('Failed to send message: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final savedMessage = ChatMessage.fromJson(
      Map<String, dynamic>.from(data['message'] as Map),
    );
    final localIndex = _messages.indexWhere((item) => item.id == message.id);
    if (localIndex != -1) {
      _messages[localIndex] = savedMessage;
      notifyListeners();
    }
  }

  void _updateThreadWithLastMessage(
    String chatId,
    String content,
    DateTime timestamp,
  ) {
    final threadIndex = _threads.indexWhere((thread) => thread.id == chatId);
    if (threadIndex == -1) return;

    final updatedThread = ChatThread(
      id: _threads[threadIndex].id,
      name: _threads[threadIndex].name,
      isGroup: _threads[threadIndex].isGroup,
      participants: _threads[threadIndex].participants,
      lastActivity: timestamp,
      lastMessage: content,
      lastMessageTime: timestamp,
      unreadCount: _threads[threadIndex].unreadCount,
    );

    _threads[threadIndex] = updatedThread;
    final thread = _threads.removeAt(threadIndex);
    _threads.insert(0, thread);
  }

  Future<String> createChatThread({
    required List<String> memberIds,
    required bool isGroup,
    String? name,
  }) async {
    final headers = await _headers(includeJson: true);
    if (headers == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.conversationsEndpoint}'),
      headers: headers,
      body: jsonEncode({
        'memberIds': memberIds,
        'isGroup': isGroup,
        if (name != null) 'name': name,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create chat: ${response.body}');
    }

    await loadChatThreads();
    return jsonDecode(response.body)['conversation']['id'];
  }

  Future<void> markAsRead(String chatId) async {
    final unreadIds =
        _messages
            .where((message) => !message.isRead)
            .map((message) => message.id)
            .toList();
    if (unreadIds.isEmpty) return;
    final headers = await _headers(includeJson: true);
    if (headers == null) return;
    await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/api/conversations/$chatId/messages/read',
      ),
      headers: headers,
      body: jsonEncode({'messageIds': unreadIds}),
    );
  }

  void setCurrentChat(String chatId) {
    if (_currentChatId != chatId) {
      _currentChatId = chatId;
      loadMessages(chatId);
      subscribeToChat(chatId);
      markAsRead(chatId);
    }
  }

  Future<void> initialize() async {
    await loadChatThreads();
  }

  @override
  void dispose() {
    _chatChannel?.sink.close();
    super.dispose();
  }

  void setMessageAddedCallback(VoidCallback callback) {
    _messageAddedCallback = callback;
  }

  void removeMessageAddedCallback() {
    _messageAddedCallback = null;
  }

  Future<String?> createGroupChat(
    String groupName,
    List<String> memberIds,
  ) async {
    try {
      return await createChatThread(
        memberIds: memberIds,
        isGroup: true,
        name: groupName,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> createMatchChat(
    String otherUserId,
    String otherUserName,
  ) async {
    try {
      return await createChatThread(
        memberIds: [otherUserId],
        isGroup: false,
        name: otherUserName,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> getUsersWithActiveChats() async {
    return _threads
        .expand((thread) => thread.participants)
        .map(
          (user) => {
            'id': user.id,
            'name': user.name,
            'email': '',
            'profilePic': user.profilePic,
          },
        )
        .toList();
  }

  Future<Map<String, dynamic>?> getUserDetailsById(String userId) async {
    final headers = await _headers();
    if (headers == null) return null;

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/users/$userId'),
      headers: headers,
    );

    if (response.statusCode != 200) return null;
    return jsonDecode(response.body)['user'];
  }

  Future<Map<String, dynamic>?> getOtherUserInChat(
    String chatId,
    String currentUserId,
  ) async {
    ChatThread? thread;
    for (final item in _threads) {
      if (item.id == chatId) {
        thread = item;
        break;
      }
    }
    final otherUser = thread?.getOtherUser(currentUserId);
    if (otherUser == null) return null;

    return {
      'id': otherUser.id,
      'name': otherUser.name,
      'email': '',
      'profilePic': otherUser.profilePic,
    };
  }
}
