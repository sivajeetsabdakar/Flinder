class UserModel {
  final String id;
  final String email;
  final String? name;
  bool? isProfileCompleted;
  bool? profileQuestionnaireSkipped;
  int? profileCompletionScore;
  final String? onlineStatus;
  final DateTime? lastOnline;
  final DateTime? createdAt;
  final String? verificationStatus;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.isProfileCompleted = false,
    this.profileQuestionnaireSkipped = false,
    this.profileCompletionScore = 0,
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
      profileQuestionnaireSkipped: json['profileQuestionnaireSkipped'] ?? false,
      profileCompletionScore: json['profileCompletionScore'] ?? 0,
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
      'isProfileCompleted': isProfileCompleted ?? false,
      'profileQuestionnaireSkipped': profileQuestionnaireSkipped ?? false,
      'profileCompletionScore': profileCompletionScore ?? 0,
      'onlineStatus': onlineStatus,
      'lastOnline': lastOnline?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'verificationStatus': verificationStatus,
    };
  }

  // Create a copy of this model with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    bool? isProfileCompleted,
    bool? profileQuestionnaireSkipped,
    int? profileCompletionScore,
    String? onlineStatus,
    DateTime? lastOnline,
    DateTime? createdAt,
    String? verificationStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      profileQuestionnaireSkipped:
          profileQuestionnaireSkipped ?? this.profileQuestionnaireSkipped,
      profileCompletionScore:
          profileCompletionScore ?? this.profileCompletionScore,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      lastOnline: lastOnline ?? this.lastOnline,
      createdAt: createdAt ?? this.createdAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}
