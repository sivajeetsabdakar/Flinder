import 'package:flutter/foundation.dart';
import 'app_user.dart';

class ChatThread {
  final String id;
  final bool isGroup;
  final String? name;
  final List<AppUser> participants;
  final DateTime? lastActivity;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int? unreadCount;

  ChatThread({
    required this.id,
    required this.isGroup,
    this.name,
    this.participants = const [],
    this.lastActivity,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    List<AppUser> participantsList = [];
    if (json['participants'] != null) {
      participantsList =
          (json['participants'] as List)
              .map((member) => AppUser.fromJson(member))
              .toList();
    }

    return ChatThread(
      id: json['id'],
      isGroup: json['is_group'] ?? false,
      name: json['name'],
      participants: participantsList,
      lastActivity:
          json['last_activity'] != null
              ? DateTime.parse(json['last_activity'])
              : null,
      lastMessage: json['last_message'],
      lastMessageTime:
          json['last_message_time'] != null
              ? DateTime.parse(json['last_message_time'])
              : null,
      unreadCount: json['unread_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_group': isGroup,
      'name': name,
      'participants': participants.map((member) => member.toJson()).toList(),
      'last_activity': lastActivity?.toIso8601String(),
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
    };
  }

  // Get other user in a 1:1 chat
  AppUser? getOtherUser(String currentUserId) {
    if (isGroup || participants.isEmpty) return null;

    for (var user in participants) {
      if (user.id != currentUserId) {
        return user;
      }
    }

    // If we couldn't find another user, return the first one
    return participants.first;
  }
}
