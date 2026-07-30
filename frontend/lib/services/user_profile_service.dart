import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../services/auth_service.dart';

class UserProfileService {
  // Logger tag
  static const String _tag = 'UserProfileService';
  static const String _questionnaireSkippedPrefix =
      'profile_questionnaire_skipped_';

  static Future<String?> _currentUserSkipKey() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return null;
    return '$_questionnaireSkippedPrefix${user.id}';
  }

  static Future<bool> hasSkippedProfileQuestionnaire() async {
    final user = await AuthService.refreshCurrentUser();
    if (user?.profileQuestionnaireSkipped != null) {
      return user!.profileQuestionnaireSkipped!;
    }
    final key = await _currentUserSkipKey();
    if (key == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<bool> setProfileQuestionnaireSkipped(bool skipped) async {
    final key = await _currentUserSkipKey();
    if (key == null) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, skipped);

    final token = await AuthService.getAuthToken();
    if (token == null) return false;

    final url = '${ApiConstants.baseUrl}${ApiConstants.onboardingSkipEndpoint}';
    final response =
        skipped
            ? await http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': token,
              },
            )
            : await http.delete(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': token,
              },
            );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await AuthService.refreshCurrentUser();
      return true;
    }

    print('$_tag - Failed to update onboarding skip: ${response.body}');
    return false;
  }

  static Future<bool> shouldShowProfileQuestionnaire() async {
    final completed = await isProfileCompleted();
    if (completed) return false;
    final skipped = await hasSkippedProfileQuestionnaire();
    return !skipped;
  }

  // Check if user profile is completed
  static Future<bool> isProfileCompleted() async {
    try {
      print('$_tag - Checking if profile is completed');

      final refreshedUser = await AuthService.refreshCurrentUser();
      if (refreshedUser != null) {
        final completed = refreshedUser.isProfileCompleted ?? false;
        print('$_tag - Profile completion status from backend: $completed');
        return completed;
      }

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null) {
        try {
          final userData = jsonDecode(userJson);
          final completed = userData['isProfileCompleted'] ?? false;
          print(
            '$_tag - Profile completion status from SharedPreferences: $completed',
          );
          if (completed) {
            return true;
          }
        } catch (e) {
          print('$_tag - Error parsing user data from SharedPreferences: $e');
        }
      }

      // If not found in SharedPreferences or not completed, try getting from User model
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        print('$_tag - No user found');
        return false;
      }

      // Check if the profile is marked as completed in the user data
      final completed = user.isProfileCompleted ?? false;
      print('$_tag - Profile completion status from UserModel: $completed');

      // If completed, make sure it's also saved in SharedPreferences for consistency
      if (completed && userJson != null) {
        try {
          final userData = jsonDecode(userJson);
          userData['isProfileCompleted'] = true;
          await prefs.setString('user', jsonEncode(userData));
          print('$_tag - Updated SharedPreferences with completed status');
        } catch (e) {
          print('$_tag - Error updating SharedPreferences: $e');
        }
      }

      return completed;
    } catch (e) {
      print('$_tag - ERROR checking profile completion: $e');
      return false;
    }
  }

  // Save user preferences to the FastAPI backend.
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
    List<String>? homeVibes,
    List<String>? dealBreakers,
    String? cookingFrequency,
    String? guestPolicy,
    String? petPreference,
    String? sleepStyle,
    String? socialBattery,
    String? conflictStyle,
    String? moveInTimeline,
    String? bio,
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
          "moveInDate": _moveInDateForTimeline(moveInTimeline),
          "leaseDuration": "long_term",
        },
        "nonCritical": {
          "bio": bio?.trim(),
          "schedule": _formatSchedule(schedule),
          "noiseLevel": _formatNoiseLevel(noiseLevel),
          "cookingFrequency": _formatFrequency(cookingFrequency ?? "Sometimes"),
          "diet": "no_restrictions",
          "smoking": "no",
          "drinking": "occasionally",
          "pets": _formatPetPreference(petPreference ?? "Pet friendly"),
          "cleaningHabits": _formatCleaningHabits(cleaningHabits),
          "guestPolicy": _formatGuestPolicy(guestPolicy ?? "Planned guests"),
          "interests": interests ?? [],
          "homeVibes": homeVibes ?? [],
          "dealBreakers": dealBreakers ?? [],
          "sleepStyle": sleepStyle,
          "socialBattery": socialBattery,
          "conflictStyle": conflictStyle,
          "moveInTimeline": moveInTimeline,
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

      // Send to the API.
      final success = await _savePreferencesToApi(user.id, preferencesData);
      print('$_tag - Save preferences result: $success');

      if (success) {
        await setProfileQuestionnaireSkipped(false);
        await AuthService.refreshCurrentUser();
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
      case 'Under ₹10,000':
        return {'min': 0, 'max': 10000};
      case '₹10,000-₹20,000':
        return {'min': 10000, 'max': 20000};
      case '₹20,000-₹35,000':
        return {'min': 20000, 'max': 35000};
      case '₹35,000+':
        return {'min': 35000, 'max': 75000};
      default:
        return {'min': 10000, 'max': 20000};
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

  static String _formatFrequency(String frequency) {
    switch (frequency) {
      case 'Most days':
        return 'daily';
      case 'Rarely':
        return 'rarely';
      case 'Sometimes':
      default:
        return 'sometimes';
    }
  }

  static String _formatGuestPolicy(String guestPolicy) {
    switch (guestPolicy) {
      case 'Quiet home':
        return 'rare_guests';
      case 'Open house':
        return 'frequent_guests';
      case 'Planned guests':
      default:
        return 'occasional_guests';
    }
  }

  static String _formatPetPreference(String petPreference) {
    switch (petPreference) {
      case 'No pets':
        return 'no_pets';
      case 'Have a pet':
        return 'has_pet';
      case 'Pet friendly':
      default:
        return 'comfortable_with_pets';
    }
  }

  static String _moveInDateForTimeline(String? timeline) {
    final now = DateTime.now();
    final days = switch (timeline) {
      'This month' => 14,
      '1-2 months' => 45,
      '3+ months' => 100,
      _ => 45,
    };
    final target = now.add(Duration(days: days));
    return target.toIso8601String().split('T').first;
  }

  // Save preferences to the backend API.
  static Future<bool> _savePreferencesToApi(
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

      final interests =
          (nonCriticalPrefs['interests'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList();
      final homeVibes =
          (nonCriticalPrefs['homeVibes'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList();
      final dealBreakers =
          (nonCriticalPrefs['dealBreakers'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList();
      final bio = (nonCriticalPrefs['bio'] as String?)?.trim();

      // Construct profile data
      final profileData = {
        'bio':
            bio?.isNotEmpty == true
                ? bio
                : 'Looking for a compatible flatmate and a calm home.',
        'interests':
            interests.isNotEmpty ? interests : ['Music', 'Movies', 'Travel'],
        'location': {
          'city': criticalPrefs['location']['city'],
          'neighborhood': criticalPrefs['location']['neighborhoods'][0],
        },
        'budget': {
          'min': criticalPrefs['budget']['min'],
          'max': criticalPrefs['budget']['max'],
          'currency': 'INR',
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
          'homeVibes': homeVibes,
          'dealBreakers': dealBreakers,
          'sleepStyle': nonCriticalPrefs['sleepStyle'],
          'socialBattery': nonCriticalPrefs['socialBattery'],
          'conflictStyle': nonCriticalPrefs['conflictStyle'],
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

  // Helper function to limit string length
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
