import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/preferences_model.dart';
import 'auth_service.dart';

class PreferencesService {
  static const String _tag = 'PreferencesService';

  static Future<Map<String, String>?> _authHeaders({
    bool includeJson = false,
  }) async {
    final token = await AuthService.getAuthToken();
    if (token == null) {
      return null;
    }

    return {
      if (includeJson) 'Content-Type': 'application/json',
      'Authorization': token,
    };
  }

  // Get the user preferences
  static Future<PreferencesModel?> getUserPreferences() async {
    try {
      print('$_tag - Getting user preferences');
      final userId = await _getUserId();
      if (userId == null) {
        print('$_tag - No user ID found');
        return null;
      }

      final url = '${ApiConstants.baseUrl}${ApiConstants.preferencesEndpoint}';
      print('$_tag - API CALL: GET $url');

      final headers = await _authHeaders();
      if (headers == null) {
        print('$_tag - No auth token available');
        return null;
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      print('$_tag - Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('$_tag - Preferences found');
        try {
          final jsonData = jsonDecode(response.body);
          print('$_tag - Response data: ${jsonData.keys.toList()}');

          // Check if the response contains preferences data
          if (jsonData.containsKey('preferences')) {
            // If the API returns preferences in a nested structure
            print('$_tag - Found nested preferences in response');
            return PreferencesModel.fromJson(jsonData['preferences']);
          } else {
            // If the API returns preferences directly
            return PreferencesModel.fromJson(jsonData);
          }
        } catch (parseError) {
          print('$_tag - Error parsing preferences JSON: $parseError');
          print('$_tag - Response body: ${response.body}');
          return PreferencesModel.createDefault(userId);
        }
      } else if (response.statusCode == 404) {
        print('$_tag - No preferences found, creating defaults');
        return PreferencesModel.createDefault(userId);
      } else {
        print('$_tag - Error getting preferences: ${response.body}');
        return null;
      }
    } catch (e) {
      print('$_tag - ERROR getting preferences: $e');
      return PreferencesModel.createDefault(await _getUserId() ?? '');
    }
  }

  // Update user interests
  static Future<bool> updateInterests(List<String> interests) async {
    try {
      print('$_tag - Updating user interests');
      final userId = await _getUserId();
      if (userId == null) {
        print('$_tag - No user ID found');
        return false;
      }

      final url = '${ApiConstants.baseUrl}${ApiConstants.preferencesEndpoint}';
      print('$_tag - API CALL: PUT $url');

      final headers = await _authHeaders(includeJson: true);
      if (headers == null) {
        print('$_tag - No auth token available');
        return false;
      }

      // Get current preferences or create defaults if none exist
      final preferences = await getUserPreferences();
      if (preferences == null) {
        print('$_tag - No preferences found to update');
        return false;
      }

      print('$_tag - Current preferences found, updating interests');

      // Convert list of interests to map format required by the model
      Map<String, List<String>> interestsMap = {};
      for (String interest in interests) {
        interestsMap[interest] = ['selected'];
      }

      // Create an updated preferences model with the new interests
      final updatedPreferences = preferences.copyWithInterests(interestsMap);

      // Format the request body with camelCase field names
      final Map<String, dynamic> body = {
        'critical': updatedPreferences.critical,
        'nonCritical': updatedPreferences.nonCritical,
        'discoverySettings': updatedPreferences.discoverySettings,
        'interests': interests, // Send as a simple list of strings
      };

      print('$_tag - Request body: $body');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      print('$_tag - Response status: ${response.statusCode}');
      print('$_tag - Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('$_tag - ERROR updating interests: $e');
      return false;
    }
  }

  // Update user preferences
  static Future<bool> updatePreferences(PreferencesModel preferences) async {
    try {
      print('$_tag - Updating user preferences');
      final userId = await _getUserId();
      if (userId == null) {
        print('$_tag - No user ID found');
        return false;
      }

      final url = '${ApiConstants.baseUrl}${ApiConstants.preferencesEndpoint}';
      print('$_tag - API CALL: PUT $url');

      final headers = await _authHeaders(includeJson: true);
      if (headers == null) {
        print('$_tag - No auth token available');
        return false;
      }

      // Format request body to match expected format
      final requestBody = {
        'critical': preferences.critical,
        'nonCritical': preferences.nonCritical,
        'discoverySettings': preferences.discoverySettings,
      };

      // Add interests if available
      if (preferences.interests != null) {
        requestBody['interests'] = Map<String, dynamic>.from(
          preferences.interests!,
        );
      }

      print('$_tag - Request body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('$_tag - Response status: ${response.statusCode}');
      print('$_tag - Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('$_tag - ERROR updating preferences: $e');
      return false;
    }
  }

  // Helper method to get the current user ID
  static Future<String?> _getUserId() async {
    final user = await AuthService.getCurrentUser();
    return user?.id;
  }
}
