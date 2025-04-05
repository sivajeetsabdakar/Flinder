import 'package:flutter/foundation.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final String? attachment;
  final String? attachmentType;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
    this.attachment,
    this.attachmentType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      content: json['content'],
      sentAt: DateTime.parse(json['sent_at']),
      isRead: true,
      attachment: json['attachment'],
      attachmentType: json['attachment_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'sent_at': sentAt.toIso8601String(),
      if (attachment != null) 'attachment': attachment,
      if (attachmentType != null) 'attachment_type': attachmentType,
    };
  }
}
