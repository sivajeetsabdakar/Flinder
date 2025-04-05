import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import '../../widgets/bottom_navigation.dart';
import '../profile/profile_screen.dart';
import '../discovery/discover_screen.dart';
import '../discovery/find_screen.dart';
import '../discovery/liked_you_screen.dart';
import '../chat/chat_screen.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/discover_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';

class MainNavigationScreen extends StatefulWidget {
  // Add optional parameter to allow setting initial tab
  final int? initialTab;

  const MainNavigationScreen({Key? key, this.initialTab}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late PageController _pageController;
  int _pendingLikesCount = 0;
  bool _isLoadingLikes = false;

  final List<Widget> _screens = [
    const ProfileScreen(), // User's own profile
    const DiscoverScreen(), // Discover networking events (unimplemented for now)
    const FindScreen(), // Swipe on users based on interests
    const LikedYouScreen(), // Show users who liked you
    const ChatScreen(), // Show conversations and messages
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with the provided tab or default to center tab (2)
    _currentIndex = widget.initialTab ?? 2;
    _pageController = PageController(initialPage: _currentIndex);

    // Check for pending likes
    _checkPendingLikes();
  }

  // Check for users who have liked the current user
  Future<void> _checkPendingLikes() async {
    if (_isLoadingLikes) return;

    setState(() {
      _isLoadingLikes = true;
    });

    try {
      // Ensure Supabase auth is initialized
      await DiscoverService.ensureSupabaseAuth();

      // Get likes from the API
      final likedUsers = await DiscoverService.getLikesReceived();

      if (mounted) {
        setState(() {
          _pendingLikesCount = likedUsers.length;
          _isLoadingLikes = false;
        });
      }

      log('Found $_pendingLikesCount pending likes');
    } catch (e) {
      log('Error checking pending likes: $e');
      if (mounted) {
        setState(() {
          _isLoadingLikes = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if we're being navigated to with an argument specifying the tab
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null &&
        arguments is int &&
        arguments >= 0 &&
        arguments < _screens.length) {
      // Only change if different to avoid unnecessary rebuilds
      if (_currentIndex != arguments) {
        setState(() {
          _currentIndex = arguments;
          // Jump to the page without animation
          _pageController.jumpToPage(arguments);
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Jump to page instead of animating to prevent swiping between tabs
    _pageController.jumpToPage(index);
    setState(() {
      _currentIndex = index;

      // Reset notification count when navigating to the Liked You tab
      if (index == AppRouter.likedYouTab) {
        _pendingLikesCount = 0;
      } else if (index == AppRouter.findTab) {
        // When navigating to Find tab, refresh the likes count
        _checkPendingLikes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show options dialog when back button is pressed
        return await _onWillPop(context);
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          children: _screens,
          physics:
              const NeverScrollableScrollPhysics(), // Prevent swiping between tabs
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        bottomNavigationBar: BottomNavigation(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          likeNotificationCount:
              _currentIndex == AppRouter.likedYouTab ? 0 : _pendingLikesCount,
        ),
      ),
    );
  }

  // Handle back button press with options to exit app or logout
  Future<bool> _onWillPop(BuildContext context) async {
    // Show options dialog
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text(
              'What would you like to do?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Choose an option below',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('cancel'),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('exit'),
                child: const Text(
                  'Exit App',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('logout'),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (result == 'logout') {
      await _handleLogout(context);
      return false; // Don't pop the route, as we're handling navigation
    }

    return result == 'exit'; // Return true only if user wants to exit
  }

  // Handle logout
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Perform logout
      await AuthService.logout();

      // Update auth provider state and navigate to login screen
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.initialize();
        AppRouter.navigateToLogin(context);
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error during logout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
