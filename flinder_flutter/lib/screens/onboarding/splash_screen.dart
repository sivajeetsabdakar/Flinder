import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../constants/api_constants.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/flinder_logo.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_profile_service.dart';

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
  bool _isInitializing = true;

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
      setState(() {
        _isInitializing = false;
      });
      _navigateToNextScreen();
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      try {
        // Check if profile is completed - first check auth provider (which handles hot reloads)
        final isProfileCompleted = authProvider.user?.profileCompleted ?? false;

        if (isProfileCompleted) {
          // Profile is completed, go to main navigation screen
          AppRouter.navigateReplacement(context, AppRouter.mainRoute);
        } else {
          // Double-check with the service (to ensure consistent behavior)
          final serviceProfileCompleted =
              await UserProfileService.isProfileCompleted();

          if (serviceProfileCompleted) {
            // Profile is completed according to the service, go to main navigation screen
            AppRouter.navigateReplacement(context, AppRouter.mainRoute);
          } else {
            // Profile is not completed, redirect to profile completion
            AppRouter.navigateToProfileCreation(context);
          }
        }
      } catch (e) {
        // Handle any errors during profile check
        print('Error checking profile completion: $e');
        // Navigate to login as fallback
        AppRouter.navigateReplacement(context, AppRouter.loginRoute);
      }
    } else {
      // Not logged in, go to login screen
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
