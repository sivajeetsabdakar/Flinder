import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/profile_model.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class ProfileService {
  static Future<ProfileModel?> getCurrentProfile() async {
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Get the current user to access the email
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('User not found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profileMeEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
          'Email': user.email, // Include the email in the headers
        },
      );

      log(
        'API Call: GET ${ApiConstants.baseUrl}${ApiConstants.profileMeEndpoint}',
      );
      log('Response Status: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true &&
            responseData['profile'] != null) {
          final profile = ProfileModel.fromJson(responseData['profile']);
          // If the API returns a valid profile, return it
          return profile;
        } else {
          // If API returns success but no profile, return a dummy profile
          log('No profile data found from API, returning dummy profile');
          return getDummyProfile();
        }
      } else if (response.statusCode == 404) {
        // If profile not found, return a dummy profile
        log('Profile not found (404), returning dummy profile');
        return getDummyProfile();
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      log('Error getting current profile: $e');
      log('Returning dummy profile due to error');
      return getDummyProfile();
    }
  }

  static Future<bool> updateProfile(ProfileModel profile) async {
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final endpoint =
          '${ApiConstants.baseUrl}${ApiConstants.profileMeEndpoint}';
      log('API Call: PUT $endpoint');
      log('Request Body: ${jsonEncode(profile.toJson())}');

      final response = await http.put(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode(profile.toJson()),
      );

      log('Response Status: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      log('Error updating profile: $e');
      return false;
    }
  }

  static Future<bool> updateBio(String userId, String bio) async {
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final endpoint =
          '${ApiConstants.baseUrl}${ApiConstants.profileEndpoint}/$userId/bio';
      log('API Call: PUT $endpoint');
      log('Request Body: ${jsonEncode({'bio': bio})}');

      final response = await http.put(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode({'bio': bio}),
      );

      log('Response Status: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Failed to update bio: ${response.statusCode}');
      }
    } catch (e) {
      log('Error updating bio: $e');
      return false;
    }
  }

  // This method returns potential matches for display in the find screen
  static Future<List<UserProfile>> getPotentialMatches() async {
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final endpoint =
          '${ApiConstants.baseUrl}${ApiConstants.potentialMatchesEndpoint}';
      log('API Call: GET $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      log('Response Status: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true &&
            responseData['profiles'] != null) {
          final List<dynamic> profilesJson = responseData['profiles'];
          // If the API returns profiles, convert them to UserProfile objects
          if (profilesJson.isNotEmpty) {
            return profilesJson
                .map((json) => UserProfile.fromJson(json))
                .toList();
          }
        }

        // If API returns success but no profiles or empty list, return dummy profiles
        log('No potential matches found from API, returning dummy profiles');
        return UserProfile.getDummyProfiles();
      } else {
        throw Exception(
          'Failed to load potential matches: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('Error getting potential matches: $e');
      log('Returning dummy profiles due to error');
      return UserProfile.getDummyProfiles();
    }
  }

  // Create a dummy profile for testing
  static ProfileModel getDummyProfile() {
    return ProfileModel(
      userId: '123456',
      bio:
          'I am looking for a nice place to live near downtown. I am clean, quiet, and respectful. I work as a software engineer and enjoy hiking on weekends.',
      interests: ['Reading', 'Hiking', 'Cooking', 'Technology', 'Movies'],
      profilePictures: [
        ProfilePicture(
          id: '1',
          url: 'https://randomuser.me/api/portraits/men/32.jpg',
          isPrimary: true,
          uploadedAt: DateTime.now(),
        ),
        ProfilePicture(
          id: '2',
          url: 'https://randomuser.me/api/portraits/men/33.jpg',
          isPrimary: false,
          uploadedAt: DateTime.now(),
        ),
      ],
      location: Location(
        city: 'San Francisco',
        neighborhood: 'Mission District',
      ),
      budget: Budget(min: 1000, max: 2000, currency: 'USD'),
      roomPreference: 'private',
      genderPreference: 'any_gender',
      moveInDate: '2023-06-01',
      leaseDuration: 'long_term',
      lifestyle: Lifestyle(
        schedule: 'early_riser',
        noiseLevel: 'moderate',
        cookingFrequency: 'daily',
        diet: 'no_restrictions',
        smoking: 'no',
        drinking: 'occasionally',
        pets: 'comfortable_with_pets',
        cleaningHabits: 'very_clean',
        guestPolicy: 'occasional_guests',
      ),
      languages: ['English', 'Spanish'],
    );
  }
}
