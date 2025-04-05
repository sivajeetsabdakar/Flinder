import 'package:flutter/material.dart';
import '../../widgets/bottom_navigation.dart';
import '../profile/profile_screen.dart';
import '../discovery/discover_screen.dart';
import '../discovery/find_screen.dart';
import '../discovery/liked_you_screen.dart';
import '../chat/chat_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2;
  final PageController _pageController = PageController(initialPage: 2);

  final List<Widget> _screens = [
    const ProfileScreen(), // User's own profile
    const DiscoverScreen(), // Discover networking events (unimplemented for now)
    const FindScreen(), // Swipe on users based on interests
    const LikedYouScreen(), // Show users who liked you
    const ChatScreen(), // Show conversations and messages
  ];

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
    );
  }
}
