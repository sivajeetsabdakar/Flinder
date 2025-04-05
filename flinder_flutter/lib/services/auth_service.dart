import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import '../models/user_model.dart';

class AuthService {
  // Storage keys
  static const String _tokenKey = 'auth_token'; // Updated to match the new key
  static const String _userKey = 'user'; // Updated to match the new key

  // Logger tag
  static const String _tag = 'AuthService';

  // Initialize method - call this at app startup
  static Future<void> initialize() async {
    // Print debug info about current auth state
    await debugPrintAuthState();
  }

  // Debug method to print auth state
  static Future<void> debugPrintAuthState() async {
    try {
      print('$_tag - DEBUG: Checking auth state in storage');
      final prefs = await SharedPreferences.getInstance();

      // Check all possible keys
      final oldTokenKey = prefs.getString('user_token');
      final newTokenKey = prefs.getString('auth_token');
      final oldUserKey = prefs.getString('user_data');
      final newUserKey = prefs.getString('user');

      print('$_tag - DEBUG: Old token exists: ${oldTokenKey != null}');
      print('$_tag - DEBUG: New token exists: ${newTokenKey != null}');
      print('$_tag - DEBUG: Old user data exists: ${oldUserKey != null}');
      print('$_tag - DEBUG: New user data exists: ${newUserKey != null}');

      // If inconsistent, try to fix it
      if (oldTokenKey != null && newTokenKey == null) {
        print('$_tag - DEBUG: Migrating old token to new key');
        await prefs.setString('auth_token', oldTokenKey);
      }

      if (oldUserKey != null && newUserKey == null) {
        print('$_tag - DEBUG: Migrating old user data to new key');
        try {
          // Try to convert the old format to new format
          final oldUserData = jsonDecode(oldUserKey);
          final user = User.fromJson(oldUserData);

          // Create a UserModel from User
          final userModel = UserModel(
            id: user.id,
            email: user.email,
            name: user.name,
            isProfileCompleted: user.profileCompleted,
          );

          // Save in the new format
          await prefs.setString('user', jsonEncode(userModel.toJson()));
          print('$_tag - DEBUG: Successfully migrated user data');
        } catch (e) {
          print('$_tag - DEBUG: Error migrating user data: $e');
        }
      }
    } catch (e) {
      print('$_tag - DEBUG ERROR: $e');
    }
  }

  // Register a new user
  static Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String dateOfBirth,
    required String gender,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'dateOfBirth': dateOfBirth,
          'gender': gender,
          if (phone != null) 'phone': phone,
        }),
      );

      final responseData = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(responseData);

      if (authResponse.success && authResponse.user != null) {
        // Save the user email as token for now (in a real app, use JWT or other token)
        await _saveUserData(email, authResponse.user!);
      }

      return authResponse;
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Login with email and password
  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(responseData);

      if (authResponse.success && authResponse.user != null) {
        // Save the user email as token for now (in a real app, use JWT or other token)
        await _saveUserData(email, authResponse.user!);

        // Print debug info
        await debugPrintAuthState();
      }

      return authResponse;
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Logout
  static Future<bool> logout() async {
    try {
      print('$_tag - Logging out user');
      final prefs = await SharedPreferences.getInstance();

      // Clear both old and new keys for complete logout
      await prefs.remove('user_token');
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
      await prefs.remove('user');

      print('$_tag - User logged out successfully');
      return true;
    } catch (e) {
      print('$_tag - ERROR during logout: $e');
      return false;
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Check both possible token keys
      final hasToken =
          prefs.getString(_tokenKey) != null ||
          prefs.getString('user_token') != null;

      print('$_tag - User is authenticated: $hasToken');
      return hasToken;
    } catch (e) {
      print('$_tag - Error checking authentication: $e');
      return false;
    }
  }

  // Get current user
  static Future<UserModel?> getCurrentUser() async {
    try {
      print('$_tag - Getting current user from storage');
      final prefs = await SharedPreferences.getInstance();

      // Try the new key first
      String? userString = prefs.getString(_userKey);

      // If not found, check the old key and migrate if possible
      if (userString == null) {
        final oldUserData = prefs.getString('user_data');
        if (oldUserData != null) {
          print('$_tag - Found user in old format, migrating');
          try {
            // Try to convert old format to new format
            final oldUser = User.fromJson(jsonDecode(oldUserData));

            // Create a UserModel from User
            final userModel = UserModel(
              id: oldUser.id,
              email: oldUser.email,
              name: oldUser.name,
              isProfileCompleted: oldUser.profileCompleted,
            );

            // Save in the new format
            userString = jsonEncode(userModel.toJson());
            await prefs.setString(_userKey, userString);
            print('$_tag - Successfully migrated user data');
          } catch (e) {
            print('$_tag - Error migrating user data: $e');
          }
        }
      }

      if (userString == null) {
        print('$_tag - No user found in storage');
        return null;
      }

      print('$_tag - User found in storage');
      final userJson = jsonDecode(userString);
      return UserModel.fromJson(userJson);
    } catch (e) {
      print('$_tag - ERROR getting current user: $e');
      return null;
    }
  }

  // Get authentication token
  static Future<String?> getAuthToken() async {
    try {
      print('$_tag - Getting auth token from storage');
      final prefs = await SharedPreferences.getInstance();

      // Try the new key first
      String? token = prefs.getString(_tokenKey);

      // If not found, check the old key and migrate if possible
      if (token == null) {
        final oldToken = prefs.getString('user_token');
        if (oldToken != null) {
          print('$_tag - Found token in old format, migrating');
          token = oldToken;
          await prefs.setString(_tokenKey, oldToken);
        }
      }

      if (token == null) {
        print('$_tag - No auth token found in storage');
      } else {
        print(
          '$_tag - Auth token retrieved: ${token.substring(0, min(10, token.length))}...',
        );
      }

      return token;
    } catch (e) {
      print('$_tag - ERROR getting auth token: $e');
      return null;
    }
  }

  // Save user data to shared preferences
  static Future<void> _saveUserData(String email, User user) async {
    try {
      print('$_tag - Saving user data to storage');
      final prefs = await SharedPreferences.getInstance();

      // Save auth token (email for now, in a real app this would be a JWT)
      await prefs.setString(_tokenKey, email);

      // Convert to UserModel format for profile completion
      final userModel = UserModel(
        id: user.id,
        email: user.email,
        name: user.name,
        isProfileCompleted: user.profileCompleted,
      );

      // Save in the new format
      await prefs.setString(_userKey, jsonEncode(userModel.toJson()));

      print('$_tag - User data saved successfully: ${user.email}');
      print('$_tag - User ID: ${user.id}');
      print('$_tag - User profile completion status: ${user.profileCompleted}');

      // Also save in the old format for backward compatibility
      await prefs.setString('user_token', email);
      await prefs.setString('user_data', jsonEncode(user.toJson()));
    } catch (e) {
      print('$_tag - ERROR saving user data: ${e.toString()}');
    }
  }

  // Reset password (placeholder for future implementation)
  static Future<AuthResponse> resetPassword(String email) async {
    try {
      // Will be implemented when backend supports it
      return AuthResponse(
        success: false,
        message: 'Password reset functionality not implemented yet',
      );
    } catch (e) {
      return AuthResponse(success: false, message: 'Error: ${e.toString()}');
    }
  }

  // Helper function to limit string length
  static int min(int a, int b) {
    return a < b ? a : b;
  }

  // Get profile completion status from storage
  static Future<bool> getProfileCompletionStatus() async {
    try {
      // Try to get from shared preferences first (faster)
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null) {
        final userData = jsonDecode(userJson);
        return userData['isProfileCompleted'] ?? false;
      }

      // Fallback to current user in memory
      final user = await getCurrentUser();
      return user?.isProfileCompleted ?? false;
    } catch (e) {
      print('AuthService: Error getting profile completion status: $e');
      return false;
    }
  }
}
