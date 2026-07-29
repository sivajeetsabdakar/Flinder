import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../constants/api_constants.dart';
import 'auth_service.dart';

class ProductionServices {
  static Future<Map<String, String>?> _headers({bool json = false}) async {
    final token = await AuthService.getAuthToken();
    if (token == null) return null;
    return {if (json) 'Content-Type': 'application/json', 'Authorization': token};
  }

  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  static Future<Map<String, dynamic>?> uploadProfilePhoto({
    required XFile file,
    bool isPrimary = false,
  }) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.mediaUploadEndpoint}?is_primary=$isPrimary',
    );
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = token;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Photo upload failed: $body');
    }
    return jsonDecode(body)['photo'] as Map<String, dynamic>?;
  }

  static Future<void> initializePush() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) return;
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await registerDevice(pushToken: token);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        registerDevice(pushToken: newToken);
      });
    } catch (_) {
      return;
    }
  }

  static Future<void> registerDevice({String? pushToken}) async {
    final headers = await _headers(json: true);
    if (headers == null) return;
    final userId = await AuthService.getCurrentUserId();
    final deviceId = userId == null ? 'flutter-device' : 'flutter-$userId';
    final platform =
        Platform.isAndroid
            ? 'android'
            : Platform.isIOS
                ? 'ios'
                : 'web';
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.devicesEndpoint}'),
      headers: headers,
      body: jsonEncode({'deviceId': deviceId, 'pushToken': pushToken, 'platform': platform}),
    );
  }

  static Future<List<dynamic>> getNotifications() async {
    final headers = await _headers();
    if (headers == null) return [];
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notificationsEndpoint}'),
      headers: headers,
    );
    if (response.statusCode != 200) return [];
    return (jsonDecode(response.body)['notifications'] as List?) ?? [];
  }

  static Future<bool> reportUser(String userId, String reason, {String? details}) async {
    final headers = await _headers(json: true);
    if (headers == null) return false;
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reportsEndpoint}'),
      headers: headers,
      body: jsonEncode({'userId': userId, 'reason': reason, if (details != null) 'details': details}),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<bool> blockUser(String userId, {String? reason}) async {
    final headers = await _headers(json: true);
    if (headers == null) return false;
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.blocksEndpoint}'),
      headers: headers,
      body: jsonEncode({'userId': userId, if (reason != null) 'reason': reason}),
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<bool> rewindSwipe() async {
    final headers = await _headers();
    if (headers == null) return false;
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.swipeRewindEndpoint}'),
      headers: headers,
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<bool> boostProfile() async {
    final headers = await _headers();
    if (headers == null) return false;
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profileBoostEndpoint}'),
      headers: headers,
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  static Future<List<dynamic>> searchLocation(String query) async {
    final headers = await _headers(json: true);
    if (headers == null) return [];
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.locationSearchEndpoint}'),
      headers: headers,
      body: jsonEncode({'query': query}),
    );
    if (response.statusCode != 200) return [];
    return (jsonDecode(response.body)['results'] as List?) ?? [];
  }
}
