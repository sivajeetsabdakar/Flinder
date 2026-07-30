import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/flinder_logo.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    );

    _gradientAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Initialize auth after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Initialize auth provider
    await authProvider.initialize();

    // Allow the splash screen to display for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      _navigateToNextScreen(context);
    }
  }

  Future<void> _navigateToNextScreen(BuildContext context) async {
    print('SplashScreen - Determining next screen');

    // First check shared preferences directly (most reliable for persistence)
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken != null) {
        print('SplashScreen - Found auth token in SharedPreferences');
      }
    } catch (e) {
      print('SplashScreen - Error accessing SharedPreferences: $e');
    }

    // Fallback to using the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      try {
        final shouldShowQuestionnaire =
            await UserProfileService.shouldShowProfileQuestionnaire();

        if (shouldShowQuestionnaire) {
          print(
            'SplashScreen - Profile questionnaire not completed or skipped, navigating to profile completion',
          );
          AppRouter.navigateToProfileCreation(context);
        } else {
          print(
            'SplashScreen - Profile complete or questionnaire skipped, navigating to main',
          );
          AppRouter.navigateReplacement(context, AppRouter.mainRoute);
        }
      } catch (e) {
        // Handle any errors during profile check
        print('SplashScreen - Error checking profile completion: $e');
        // Navigate to login as fallback
        AppRouter.navigateReplacement(context, AppRouter.loginRoute);
      }
    } else {
      // Not logged in, go to login screen
      print('SplashScreen - Not authenticated, navigating to login');
      AppRouter.navigateReplacement(context, AppRouter.loginRoute);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft.add(
                  Alignment(_gradientAnimation.value * 0.4, 0),
                ),
                end: Alignment.bottomRight.add(
                  Alignment(0, _gradientAnimation.value * -0.4),
                ),
                colors: [
                  AppTheme.darkerPurple,
                  AppTheme.primaryPurple,
                  AppTheme.lightPurple.withOpacity(0.8),
                ],
                stops: [0.1, 0.5 + (_gradientAnimation.value * 0.1), 0.9],
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _animation,
                child: const FlinderLogo(
                  isCircular: true,
                  size: 150,
                  showTagline: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
