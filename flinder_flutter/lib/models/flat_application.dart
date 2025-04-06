class FlatApplication {
  final String id;
  final String flatId;
  final String groupChatId;
  final String userId;
  final String status; // "pending", "approved", "rejected"
  final DateTime createdAt;
  final DateTime? updatedAt;

  FlatApplication({
    required this.id,
    required this.flatId,
    required this.groupChatId,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory FlatApplication.fromJson(Map<String, dynamic> json) {
    return FlatApplication(
      id: json['id'],
      flatId: json['flat_id'],
      groupChatId: json['group_chat_id'],
      userId: json['user_id'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flat_id': flatId,
      'group_chat_id': groupChatId,
      'user_id': userId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
