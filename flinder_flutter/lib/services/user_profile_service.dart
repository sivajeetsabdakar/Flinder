import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';

class UserProfileService {
  // Logger tag
  static const String _tag = 'UserProfileService';

  // Check if user profile is completed
  static Future<bool> isProfileCompleted() async {
    try {
      print('$_tag - Checking if profile is completed');
      // Get the current user
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        print('$_tag - No user found');
        return false;
      }

      // Check if the profile is marked as completed in the user data
      final completed = user.isProfileCompleted ?? false;
      print('$_tag - Profile completion status: $completed');
      return completed;
    } catch (e) {
      print('$_tag - ERROR checking profile completion: $e');
      return false;
    }
  }

  // Update the profile completion status
  static Future<bool> updateProfileStatus(bool isCompleted) async {
    try {
      print('$_tag - Updating profile completion status to: $isCompleted');
      // Get the current user
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        print('$_tag - No user found for updating profile status');
        return false;
      }

      // Update the user model
      user.isProfileCompleted = isCompleted;

      // Save in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
      print('$_tag - User profile status updated in local storage');

      // Update in the backend (Supabase)
      await _updateUserProfileInBackend(user);

      return true;
    } catch (e) {
      print('$_tag - ERROR updating profile status: $e');
      return false;
    }
  }

  // Save user preferences to Supabase
  static Future<bool> savePreferences({
    required String city,
    required String roomType,
    required String budgetRange,
    required String schedule,
    required String noiseLevel,
    required String cleaningHabits,
    required int age,
    required RangeValues ageRange,
    required double maxDistance,
    required bool showMeToOthers,
    List<String>? interests,
  }) async {
    try {
      print('$_tag - Saving user preferences');
      // Get current user
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        print('$_tag - No user found for saving preferences');
        return false;
      }

      // Convert budget range to numeric values
      Map<String, double> budgetValues = _parseBudgetRange(budgetRange);
      print(
        '$_tag - Parsed budget range: $budgetRange to min: ${budgetValues['min']}, max: ${budgetValues['max']}',
      );

      // Format preferences according to API requirements
      Map<String, dynamic> preferencesData = {
        "critical": {
          "location": {
            "city": city,
            "neighborhoods": ["Mission District", "SoMa", "Hayes Valley"],
            "maxDistance": maxDistance.toInt(),
          },
          "budget": {"min": budgetValues['min'], "max": budgetValues['max']},
          "roomType": roomType.toLowerCase(),
          "genderPreference": "same_gender",
          "moveInDate": "2023-05-01",
          "leaseDuration": "long_term",
        },
        "nonCritical": {
          "schedule": _formatSchedule(schedule),
          "noiseLevel": _formatNoiseLevel(noiseLevel),
          "cookingFrequency": "daily",
          "diet": "no_restrictions",
          "smoking": "no",
          "drinking": "occasionally",
          "pets": "comfortable_with_pets",
          "cleaningHabits": _formatCleaningHabits(cleaningHabits),
          "guestPolicy": "occasional_guests",
          "interests": interests ?? [],
          "interestWeights": {
            "music": 5,
            "gaming": 4,
            "fitness": 3,
            "reading": 2,
          },
        },
        "discoverySettings": {
          "ageRange": {
            "min": ageRange.start.toInt(),
            "max": ageRange.end.toInt(),
          },
          "distance": maxDistance.toInt(),
          "showMeToOthers": showMeToOthers,
        },
      };

      print('$_tag - Sending preferences data: ${jsonEncode(preferencesData)}');

      // Send to Supabase API
      final success = await _savePreferencesToSupabase(
        user.id,
        preferencesData,
      );
      print('$_tag - Save preferences result: $success');

      if (success) {
        // Mark profile as completed if preferences were saved successfully
        await updateProfileStatus(true);
        return true;
      }

      return false;
    } catch (e) {
      print('$_tag - ERROR saving preferences: $e');
      return false;
    }
  }

  // Helper method to parse budget range string to min/max values
  static Map<String, double> _parseBudgetRange(String budgetRange) {
    switch (budgetRange) {
      case 'Under \$500':
        return {'min': 0, 'max': 500};
      case '\$500-\$1000':
        return {'min': 500, 'max': 1000};
      case '\$1000-\$1500':
        return {'min': 1000, 'max': 1500};
      case '\$1500+':
        return {'min': 1500, 'max': 3000};
      default:
        return {'min': 0, 'max': 1000};
    }
  }

  // Helper methods to format preferences for API
  static String _formatSchedule(String schedule) {
    switch (schedule) {
      case 'Early Riser':
        return 'early_riser';
      case 'Night Owl':
        return 'night_owl';
      case 'Flexible':
      default:
        return 'flexible';
    }
  }

  static String _formatNoiseLevel(String noiseLevel) {
    switch (noiseLevel) {
      case 'Silent':
        return 'quiet';
      case 'Loud':
        return 'loud';
      case 'Moderate':
      default:
        return 'moderate';
    }
  }

  static String _formatCleaningHabits(String cleaningHabits) {
    switch (cleaningHabits) {
      case 'Very Clean':
        return 'very_clean';
      case 'Messy':
        return 'casual';
      case 'Average':
      default:
        return 'average';
    }
  }

  // Save preferences to Supabase
  static Future<bool> _savePreferencesToSupabase(
    String userId,
    Map<String, dynamic> preferencesData,
  ) async {
    // First save the preferences to the API
    final preferencesUrl =
        '${ApiConstants.baseUrl}${ApiConstants.preferencesEndpoint}';
    print('$_tag - API CALL: PUT $preferencesUrl');

    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        print('$_tag - No auth token available');
        return false;
      }

      print(
        '$_tag - Request headers: Authorization: ${token.substring(0, min(10, token.length))}..., Content-Type: application/json',
      );

      final preferencesResponse = await http.put(
        Uri.parse(preferencesUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode(preferencesData),
      );

      print(
        '$_tag - Preferences Response status: ${preferencesResponse.statusCode}',
      );
      print('$_tag - Preferences Response body: ${preferencesResponse.body}');

      if (preferencesResponse.statusCode != 200) {
        print(
          '$_tag - Failed to save preferences: ${preferencesResponse.body}',
        );
        return false;
      }

      // Now create/update the profile using the /api/profile/me endpoint
      final profileSuccess = await _createOrUpdateProfile(preferencesData);

      if (!profileSuccess) {
        print('$_tag - Failed to create/update profile');
        return false;
      }

      print('$_tag - Preferences and profile saved successfully');
      return true;
    } catch (e) {
      print('$_tag - ERROR saving preferences to backend: $e');
      return false;
    }
  }

  // Create or update the user profile
  static Future<bool> _createOrUpdateProfile(
    Map<String, dynamic> preferencesData,
  ) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.profileMeEndpoint}';
    print('$_tag - API CALL: PUT $url');

    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        print('$_tag - No auth token available for profile creation/update');
        return false;
      }

      // Extract relevant data from preferences to create profile
      final criticalPrefs = preferencesData['critical'];
      final nonCriticalPrefs = preferencesData['nonCritical'];

      // Construct profile data
      final profileData = {
        'bio': 'Looking for a great place to live!', // Default bio
        'interests': ['Music', 'Movies', 'Travel'], // Default interests
        'location': {
          'city': criticalPrefs['location']['city'],
          'neighborhood': criticalPrefs['location']['neighborhoods'][0],
        },
        'budget': {
          'min': criticalPrefs['budget']['min'],
          'max': criticalPrefs['budget']['max'],
          'currency': 'USD',
        },
        'roomPreference': criticalPrefs['roomType'],
        'genderPreference': criticalPrefs['genderPreference'],
        'moveInDate': criticalPrefs['moveInDate'],
        'leaseDuration': criticalPrefs['leaseDuration'],
        'lifestyle': {
          'schedule': nonCriticalPrefs['schedule'],
          'noiseLevel': nonCriticalPrefs['noiseLevel'],
          'cookingFrequency': nonCriticalPrefs['cookingFrequency'],
          'diet': nonCriticalPrefs['diet'],
          'smoking': nonCriticalPrefs['smoking'],
          'drinking': nonCriticalPrefs['drinking'],
          'pets': nonCriticalPrefs['pets'],
          'cleaningHabits': nonCriticalPrefs['cleaningHabits'],
          'guestPolicy': nonCriticalPrefs['guestPolicy'],
        },
        'languages': ['English'],
      };

      print('$_tag - Profile request body: ${jsonEncode(profileData)}');

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode(profileData),
      );

      print('$_tag - Profile Response status: ${response.statusCode}');
      print('$_tag - Profile Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('$_tag - ERROR creating/updating profile: $e');
      return false;
    }
  }

  // Update user profile in the backend
  static Future<void> _updateUserProfileInBackend(UserModel user) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.userEndpoint}/${user.id}';
    print('$_tag - API CALL: PUT $url');

    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        print('$_tag - No auth token available for profile update');
        return;
      }

      final requestBody = {'isProfileCompleted': user.isProfileCompleted};
      print('$_tag - Request body: ${jsonEncode(requestBody)}');
      print(
        '$_tag - Request headers: Authorization: ${token.substring(0, min(10, token.length))}..., Content-Type: application/json',
      );

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode(requestBody),
      );

      print('$_tag - Response status: ${response.statusCode}');
      print('$_tag - Response body: ${response.body}');

      if (response.statusCode != 200) {
        print(
          '$_tag - Failed to update user profile in backend: ${response.body}',
        );
      }
    } catch (e) {
      print('$_tag - ERROR updating user profile in backend: $e');
    }
  }

  // Helper function to limit string length
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
