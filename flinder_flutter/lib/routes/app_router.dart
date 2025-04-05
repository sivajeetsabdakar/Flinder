import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/onboarding/home_screen.dart';
import '../screens/profile/profile_detail_screen.dart';
import '../screens/discovery/matches_screen.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/profile/profile_completion_screen.dart';
import '../screens/navigation/main_navigation_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/discovery/discover_screen.dart';
import '../screens/discovery/find_screen.dart';
import '../screens/discovery/liked_you_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/discovery/flat_detail_screen.dart';
import '../models/user_profile.dart';

class AppRouter {
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String homeRoute = '/home';
  static const String mainRoute = '/main';
  static const String profileScreenRoute = '/profile-screen';
  static const String discoverRoute = '/discover';
  static const String findRoute = '/find';
  static const String likedYouRoute = '/liked-you';
  static const String chatRoute = '/chat';
  static const String profileDetailRoute = '/profile-detail';
  static const String matchesRoute = '/matches';
  static const String profileCompletionRoute = '/profile-completion';
  static const String editProfileRoute = '/edit-profile';
  static const String flatDetailRoute = '/flat-detail';

  // Tab indices
  static const int profileTab = 0;
  static const int discoverTab = 1;
  static const int findTab = 2;
  static const int likedYouTab = 3;
  static const int chatTab = 4;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Handle the root route by redirecting to the main route
    if (settings.name == '/') {
      return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
    }

    switch (settings.name) {
      case splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signupRoute:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case homeRoute:
        // Check if we're passing a specific tab to navigate to
        final args = settings.arguments;
        if (args != null && args is int) {
          return MaterialPageRoute(
            builder: (_) => MainNavigationScreen(initialTab: args),
          );
        }
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case mainRoute:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case profileScreenRoute:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case discoverRoute:
        return MaterialPageRoute(builder: (_) => const DiscoverScreen());
      case findRoute:
        return MaterialPageRoute(builder: (_) => const FindScreen());
      case likedYouRoute:
        return MaterialPageRoute(builder: (_) => const LikedYouScreen());
      case chatRoute:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      case profileDetailRoute:
        final userProfile = settings.arguments as UserProfile;
        return MaterialPageRoute(
          builder: (_) => ProfileDetailScreen(profile: userProfile),
        );
      case matchesRoute:
        return MaterialPageRoute(builder: (_) => const MatchesScreen());
      case profileCompletionRoute:
        return MaterialPageRoute(
          builder: (_) => const ProfileCompletionScreen(),
        );
      case editProfileRoute:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case flatDetailRoute:
        final flatId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => FlatDetailScreen(flatId: flatId),
        );
      // Other routes will be added here as they are implemented
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return generateRoute(settings);
  }

  static String getInitialRoute(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      return mainRoute;
    } else {
      return loginRoute;
    }
  }

  // Navigation helpers
  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, loginRoute, (route) => false);
  }

  static void navigateToSignup(BuildContext context) {
    Navigator.pushNamed(context, signupRoute);
  }

  static void navigateToForgotPassword(BuildContext context) {
    Navigator.pushNamed(context, forgotPasswordRoute);
  }

  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
  }

  static void navigateToMain(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, mainRoute, (route) => false);
  }

  // Profile creation navigation helper
  static void navigateToProfileCreation(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      profileCompletionRoute,
      (route) => false,
    );
  }

  static void navigateToEditProfile(BuildContext context) {
    Navigator.pushNamed(context, editProfileRoute);
  }

  static void navigateReplacement(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  // Navigation helper for flat details
  static void navigateToFlatDetail(BuildContext context, String flatId) {
    Navigator.pushNamed(context, flatDetailRoute, arguments: flatId);
  }

  static void navigateToLikedYouTab(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      homeRoute,
      (Route<dynamic> route) => false,
      arguments: likedYouTab,
    );
  }
}
