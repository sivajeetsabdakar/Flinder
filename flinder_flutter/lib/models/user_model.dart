class UserModel {
  final String id;
  final String email;
  final String? name;
  bool? isProfileCompleted;
  final String? onlineStatus;
  final DateTime? lastOnline;
  final DateTime? createdAt;
  final String? verificationStatus;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.isProfileCompleted = false,
    this.onlineStatus,
    this.lastOnline,
    this.createdAt,
    this.verificationStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      isProfileCompleted: json['isProfileCompleted'] ?? false,
      onlineStatus: json['onlineStatus'],
      lastOnline:
          json['lastOnline'] != null
              ? DateTime.parse(json['lastOnline'])
              : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      verificationStatus: json['verificationStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'isProfileCompleted': isProfileCompleted,
      'onlineStatus': onlineStatus,
      'lastOnline': lastOnline?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'verificationStatus': verificationStatus,
    };
  }
}
