import 'user.dart';

class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final User? user;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final detail = json['detail'];
    final detailMessage =
        detail is String
            ? detail
            : detail is List && detail.isNotEmpty
            ? detail.first['msg']?.toString()
            : null;

    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? detailMessage ?? 'Authentication failed',
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'user': user?.toJson(),
    };
  }
}
