import 'user.dart';

class AuthResponse {
  final bool success;
  final String message;
  final User? user;

  AuthResponse({required this.success, required this.message, this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'user': user?.toJson()};
  }
}
