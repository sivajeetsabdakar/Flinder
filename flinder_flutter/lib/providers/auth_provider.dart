import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../models/auth_response.dart';

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
      // Check if user is logged in
      final isAuth = await AuthService.isAuthenticated();
      if (isAuth) {
        final userModel = await AuthService.getCurrentUser();
        _user = userModel != null ? User.fromUserModel(userModel) : null;

        // Check if this is a development hot reload - maintain the profile completion status
        // This prevents redirecting to profile completion after hot reload
        if (_user != null && !(_user!.profileCompleted)) {
          // Only check local storage again if profile is not completed in memory
          try {
            final storedCompleted =
                await AuthService.getProfileCompletionStatus();
            if (storedCompleted) {
              // Create a new User instance with updated profile completion status
              _user = User(
                id: _user!.id,
                email: _user!.email,
                name: _user!.name,
                profileCompleted: true,
                onlineStatus: _user!.onlineStatus,
                lastOnline: _user!.lastOnline,
                createdAt: _user!.createdAt,
                verificationStatus: _user!.verificationStatus,
              );
              print(
                'Auth Provider: Restored profile completion status from storage',
              );
            }
          } catch (e) {
            print('Auth Provider: Error checking stored profile status: $e');
          }
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
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
