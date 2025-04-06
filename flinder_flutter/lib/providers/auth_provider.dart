import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../models/auth_response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  // Initialize the auth state
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      print('AuthProvider - Initializing');

      // Check if user is logged in
      final isAuth = await AuthService.isAuthenticated();
      if (isAuth) {
        // Try to read directly from SharedPreferences first for more reliable persistence
        bool profileCompletedFromPrefs = false;
        try {
          final prefs = await SharedPreferences.getInstance();
          final userJson = prefs.getString('user');
          if (userJson != null) {
            final userData = jsonDecode(userJson);
            profileCompletedFromPrefs = userData['isProfileCompleted'] ?? false;
            print(
              'AuthProvider - Profile completion from SharedPreferences: $profileCompletedFromPrefs',
            );
          }
        } catch (e) {
          print('AuthProvider - Error reading from SharedPreferences: $e');
        }

        // Get user model
        final userModel = await AuthService.getCurrentUser();
        if (userModel != null) {
          // Create User from UserModel, ensuring profile completion status is consistent
          if (profileCompletedFromPrefs &&
              userModel.isProfileCompleted != true) {
            // Update the UserModel if SharedPreferences has it as completed
            userModel.isProfileCompleted = true;

            // Save back the updated status
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user', jsonEncode(userModel.toJson()));
              print(
                'AuthProvider - Updated UserModel in SharedPreferences with completed status',
              );
            } catch (e) {
              print('AuthProvider - Error updating SharedPreferences: $e');
            }
          }

          _user = User.fromUserModel(userModel);
          print(
            'AuthProvider - User logged in: ${_user?.email}, profileCompleted: ${_user?.profileCompleted}',
          );
        }
      } else {
        print('AuthProvider - No user authenticated');
      }
    } catch (e) {
      _error = e.toString();
      print('AuthProvider - Error during initialization: $_error');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
      print('AuthProvider - Initialization complete');
    }
  }

  // Register a new user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String dateOfBirth,
    required String gender,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.register(
        email: email,
        password: password,
        name: name,
        dateOfBirth: dateOfBirth,
        gender: gender,
        phone: phone,
      );

      if (response.success && response.user != null) {
        _user = response.user;
      } else {
        _error = response.message;
      }

      return response;
    } catch (e) {
      _error = e.toString();
      return AuthResponse(
        success: false,
        message: 'Registration failed: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.login(
        email: email,
        password: password,
      );

      if (response.success && response.user != null) {
        _user = response.user;
      } else {
        _error = response.message;
      }

      return response;
    } catch (e) {
      _error = e.toString();
      return AuthResponse(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout user
  Future<bool> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await AuthService.logout();
      if (result) {
        _user = null;
        _error = null;
      }
      return result;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<AuthResponse> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.resetPassword(email);

      if (!response.success) {
        _error = response.message;
      }

      return response;
    } catch (e) {
      _error = e.toString();
      return AuthResponse(
        success: false,
        message: 'Password reset failed: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear any error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
