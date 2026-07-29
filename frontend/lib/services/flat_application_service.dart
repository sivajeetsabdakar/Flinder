import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/flat_application.dart';
import '../services/auth_service.dart';

class FlatApplicationService {
  static const String baseUrl = ApiConstants.baseUrl;

  static Future<Map<String, String>> _headers({
    bool includeJson = false,
  }) async {
    final token = await AuthService.getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    return {
      if (includeJson) 'Content-Type': 'application/json',
      'Authorization': token,
    };
  }

  static Future<FlatApplication> applyForFlat({
    required String flatId,
    required String groupChatId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/flats/$flatId/applications'),
      headers: await _headers(includeJson: true),
      body: jsonEncode({'groupChatId': groupChatId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to apply for flat: ${response.body}');
    }

    return FlatApplication.fromJson(jsonDecode(response.body)['application']);
  }

  static Future<List<FlatApplication>> getApplicationsForFlat(
    String flatId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/flats/$flatId/applications'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch flat applications: ${response.body}');
    }

    final applications = jsonDecode(response.body)['applications'] as List;
    return applications
        .map((item) => FlatApplication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<FlatApplication>> getUserApplications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/flats/applications/me'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch user applications: ${response.body}');
    }

    final applications = jsonDecode(response.body)['applications'] as List;
    return applications
        .map((item) => FlatApplication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<FlatApplication> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/flats/applications/$applicationId'),
      headers: await _headers(includeJson: true),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update application status: ${response.body}');
    }

    return FlatApplication.fromJson(jsonDecode(response.body)['application']);
  }
}
