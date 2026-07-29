# 💬 ChatContext Guide for Flutter + Supabase + Express.js

This comprehensive guide explains how to implement a **real-time chat system** in your Flutter application by leveraging:

- **Supabase Realtime**: For real-time message subscription and listening
- **Express.js server**: For secure message handling, authentication, and business logic
- **Flutter ChatContext**: For state management and UI updates

## 🚀 Key Benefits

- **Real-time updates**: Messages appear instantly without polling
- **Separation of concerns**: Server handles validation and security
- **Scalable architecture**: Well-structured for future expansion
- **Clean state management**: Using ChangeNotifier pattern

---

## 📦 1. Flutter Data Models

Well-structured data models are the foundation of a reliable chat system. These models represent your core data entities.

### 🧑 User Model

Represents a user in the chat system.

```dart
class AppUser {
  final String id;
  final String name;
  final String? profilePic;

  AppUser({required this.id, required this.name, this.profilePic});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      name: json['name'],
      profilePic: json['profile_pic'],
    );
  }
}
```

### 💬 Message Model

Represents an individual chat message.

```dart
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      content: json['content'],
      sentAt: DateTime.parse(json['sent_at']),
    );
  }
}
```

### 🧵 Chat Thread Model

Represents a conversation between two or more users.

```dart
class ChatThread {
  final String id;
  final bool isGroup;
  final String? name;
  final List<AppUser> members;

  ChatThread({
    required this.id,
    required this.isGroup,
    this.name,
    required this.members
  });
}
```

---

## 🔄 2. ChatContext Implementation

The `ChatContext` class serves as the central hub for chat functionality, connecting your UI with the backend services.

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatContext extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;

  // Load existing messages from Express server
  Future<void> loadMessages(String chatId) async {
    final response = await http.get(
      Uri.parse('https://yourserver.com/api/chat/$chatId/messages')
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      _messages = jsonList.map((m) => ChatMessage.fromJson(m)).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load messages: ${response.reasonPhrase}');
    }
  }

  // Subscribe to real-time message updates using Supabase Realtime
  void subscribeToChat(String chatId) {
    // Cancel existing subscription if any
    _messageSubscription?.cancel();

    // Create new subscription
    _messageSubscription = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .listen((List<Map<String, dynamic>> data) {
      _messages = data.map((e) => ChatMessage.fromJson(e)).toList();
      notifyListeners();
    });
  }

  // Send a message via Express API
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('https://yourserver.com/api/send-message'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chat_id': chatId,
        'sender_id': senderId,
        'content': content,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  // Clean up resources when no longer needed
  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
```

---

## 🔗 3. Architecture Flow

Understanding the data flow is crucial for debugging and extending your chat implementation.

### ✉️ Sending Messages Flow

```
Flutter App ── HTTP POST ──▶ Express Server ──▶ Supabase DB (insert)
   │                             │
   └─ Payload:                   └─ Actions:
      • chat_id                     • Validate request
      • sender_id                   • Apply business rules
      • content                     • Insert to database
                                    • Return confirmation
```

1. UI triggers `sendMessage()` in ChatContext
2. Request is sent to Express server with message data
3. Server validates and processes the message
4. Message is stored in Supabase database
5. Client receives success/failure response

### 📡 Receiving Messages Flow (Realtime)

```
Supabase DB ──▶ Supabase Realtime ──▶ Flutter ChatContext ──▶ UI updates
   │                │                       │                     │
   └─ Event:        └─ Channel:             └─ Actions:           └─ Result:
      • insert         • messages table        • Update _messages    • New message
      • update         • Filtered by             list                  appears
                         chat_id              • Notify listeners     • UI refreshes
```

1. ChatContext subscribes to Supabase Realtime channel
2. New message is inserted into database
3. Supabase Realtime triggers event
4. Flutter app receives the update via stream
5. ChatContext updates message list and notifies listeners
6. UI automatically refreshes with new message

---

## 🌐 4. Express API Endpoints

Your Express.js server provides these key endpoints for chat functionality:

| Endpoint                       | Method | Description                             | Parameters                        |
| ------------------------------ | ------ | --------------------------------------- | --------------------------------- |
| `/api/send-message`            | POST   | Sends a new message                     | `chat_id`, `sender_id`, `content` |
| `/api/chat/:chatId/messages`   | GET    | Retrieves messages for a specific chat  | `chatId` (path param)             |
| `/api/available-chats/:userId` | GET    | Lists available chat threads for a user | `userId` (path param)             |

### Example Express Route Implementation

```javascript
// Example of the send-message endpoint in Express
app.post("/api/send-message", authenticateUser, async (req, res) => {
  try {
    const { chat_id, sender_id, content } = req.body;

    // Validate user is part of this chat
    const isMember = await db.query(
      "SELECT EXISTS(SELECT 1 FROM chat_members WHERE chat_id = $1 AND user_id = $2)",
      [chat_id, sender_id]
    );

    if (!isMember.rows[0].exists) {
      return res
        .status(403)
        .json({ error: "User not authorized for this chat" });
    }

    // Insert message
    const result = await db.query(
      "INSERT INTO messages(chat_id, sender_id, content) VALUES($1, $2, $3) RETURNING *",
      [chat_id, sender_id, content]
    );

    res.status(200).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

---

## 🧩 5. UI Integration

Connect your ChatContext to the UI using a Provider or other state management approach:

```dart
// In your main.dart or relevant widget
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatContext(),
      child: MyApp(),
    ),
  );
}

// In your chat screen
class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();

    // Load existing messages
    Provider.of<ChatContext>(context, listen: false)
      .loadMessages(widget.chatId);

    // Subscribe to realtime updates
    Provider.of<ChatContext>(context, listen: false)
      .subscribeToChat(widget.chatId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Consumer<ChatContext>(
        builder: (context, chatContext, child) {
          return ListView.builder(
            itemCount: chatContext.messages.length,
            itemBuilder: (context, index) {
              final message = chatContext.messages[index];
              return MessageBubble(message: message);
            },
          );
        },
      ),
      // Message input field and send button...
    );
  }
}
```

---

## ✅ Best Practices and Final Notes

- **Security**: Always validate user permissions on the server before allowing message operations
- **Efficiency**: Use Supabase Realtime for listening only (no need to poll for updates)
- **Separation**: Use Express.js for sending (providing auth, logic, and validations)
- **Resource management**: Always cancel subscriptions in `dispose()` method
- **Error handling**: Implement robust error handling for network failures
- **Offline support**: Consider adding local caching for offline message composition
- **Performance**: Implement pagination for loading large message histories

By following this architecture, you create a robust, maintainable, and scalable chat system that provides a smooth real-time experience for your users.

---

## 📚 Further Resources

- [Supabase Realtime Documentation](https://supabase.io/docs/guides/realtime)
- [Express.js Documentation](https://expressjs.com/)
- [Flutter Provider Package](https://pub.dev/packages/provider)
- [Flutter HTTP Package](https://pub.dev/packages/http)
