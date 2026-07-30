class User {
  final String id;
  final String email;
  final String name;
  final bool profileCompleted;
  final bool profileQuestionnaireSkipped;
  final int profileCompletionScore;
  final String? onlineStatus;
  final DateTime? lastOnline;
  final DateTime? createdAt;
  final VerificationStatus? verificationStatus;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.profileCompleted,
    this.profileQuestionnaireSkipped = false,
    this.profileCompletionScore = 0,
    this.onlineStatus,
    this.lastOnline,
    this.createdAt,
    this.verificationStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      profileCompleted: json['profileCompleted'] ?? false,
      profileQuestionnaireSkipped: json['profileQuestionnaireSkipped'] ?? false,
      profileCompletionScore: json['profileCompletionScore'] ?? 0,
      onlineStatus: json['onlineStatus'],
      lastOnline:
          json['lastOnline'] != null
              ? DateTime.parse(json['lastOnline'])
              : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      verificationStatus:
          json['verificationStatus'] != null
              ? VerificationStatus.fromJson(json['verificationStatus'])
              : null,
    );
  }

  // Convert from UserModel to User
  factory User.fromUserModel(dynamic userModel) {
    return User(
      id: userModel.id,
      email: userModel.email,
      name: userModel.name ?? 'User',
      profileCompleted: userModel.isProfileCompleted ?? false,
      profileQuestionnaireSkipped:
          userModel.profileQuestionnaireSkipped ?? false,
      profileCompletionScore: userModel.profileCompletionScore ?? 0,
      onlineStatus: userModel.onlineStatus,
      lastOnline: userModel.lastOnline,
      createdAt: userModel.createdAt,
      verificationStatus:
          userModel.verificationStatus != null
              ? VerificationStatus(
                email: userModel.verificationStatus.contains('email'),
                phone: userModel.verificationStatus.contains('phone'),
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileCompleted': profileCompleted,
      'profileQuestionnaireSkipped': profileQuestionnaireSkipped,
      'profileCompletionScore': profileCompletionScore,
      'onlineStatus': onlineStatus,
      'lastOnline': lastOnline?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'verificationStatus': verificationStatus?.toJson(),
    };
  }
}

class VerificationStatus {
  final bool email;
  final bool phone;

  VerificationStatus({required this.email, required this.phone});

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      email: json['email'] ?? false,
      phone: json['phone'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'phone': phone};
  }
}
