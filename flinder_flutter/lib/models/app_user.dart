import 'package:flutter/foundation.dart';

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

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'profile_pic': profilePic};
  }

  // Create from UserModel for compatibility with existing code
  factory AppUser.fromUserModel(dynamic userModel) {
    return AppUser(
      id: userModel.id,
      name: userModel.name ?? 'User',
      profilePic: null, // Add profile pic if available in your UserModel
    );
  }
}
