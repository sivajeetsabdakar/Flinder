import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/discover_profile_model.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class DiscoverService {
  static Future<bool> ensureBackendAuth() async {
    final token = await AuthService.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> ensureSupabaseAuth() => ensureBackendAuth();

  static Future<Map<String, String>?> _authHeaders({
    bool includeJson = false,
  }) async {
    final token = await AuthService.getAuthToken();
    if (token == null) return null;

    return {
      if (includeJson) 'Content-Type': 'application/json',
      'Authorization': token,
    };
  }

  static Future<bool> recordSwipe({
    required String targetUserId,
    required String direction,
  }) async {
    if (direction != 'left' && direction != 'right') {
      log('Invalid swipe direction: $direction');
      return false;
    }

    final headers = await _authHeaders(includeJson: true);
    if (headers == null) return false;

    final action = direction == 'left' ? 'like' : 'pass';
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.discoverEndpoint}/swipe',
      ),
      headers: headers,
      body: jsonEncode({'targetUserId': targetUserId, 'action': action}),
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<List<UserProfile>> getDiscoverProfiles() async {
    try {
      final headers = await _authHeaders();
      if (headers == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.discoverEndpoint}'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Discover API failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final profiles = data['profiles'];
      if (data['success'] != true || profiles is! List) return [];

      return profiles
          .map(
            (profile) =>
                DiscoverProfileModel.fromJson(
                  Map<String, dynamic>.from(profile as Map),
                ).toUserProfile(),
          )
          .toList();
    } catch (e) {
      log('Error loading discover profiles: $e');
      return ApiConstants.allowDummyFallback ? UserProfile.getDummyProfiles() : [];
    }
  }

  static Future<List<UserProfile>> getLikesReceived() async {
    try {
      final headers = await _authHeaders();
      if (headers == null) return [];

      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.discoverEndpoint}/likes',
        ),
        headers: headers,
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final profiles = data['profiles'];
      if (profiles is! List) return [];

      return profiles
          .map(
            (profile) =>
                DiscoverProfileModel.fromJson(
                  Map<String, dynamic>.from(profile as Map),
                ).toUserProfile(),
          )
          .toList();
    } catch (e) {
      log('Error loading likes received: $e');
      return [];
    }
  }

  static Future<bool> respondToLike({
    required String likeId,
    required String userId,
    required bool isAccepted,
  }) async {
    final headers = await _authHeaders(includeJson: true);
    if (headers == null) return false;

    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.discoverEndpoint}/likes/$likeId/respond',
      ),
      headers: headers,
      body: jsonEncode({'userId': userId, 'isAccepted': isAccepted}),
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }
}
