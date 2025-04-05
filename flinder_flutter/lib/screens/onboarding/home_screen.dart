import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_card.dart';
import '../../routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../profile/profile_detail_screen.dart';
import '../../widgets/flinder_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final CardSwiperController _cardController = CardSwiperController();
  late List<UserProfile> _profiles;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Load profiles after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfiles();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _profiles = UserProfile.getDummyProfiles();
        _isLoading = false;
      });
    }
  }

  void _reloadProfiles() {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });

      // Reload profiles after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _loadProfiles();
        }
      });
    }
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    if (currentIndex == null) {
      // No more cards
      _reloadProfiles();
      return true;
    }

    final swipedProfile = _profiles[previousIndex];

    // Show feedback based on swipe direction
    String message = '';

    if (direction == CardSwiperDirection.left) {
      message = "Not interested in ${swipedProfile.name}";
    } else if (direction == CardSwiperDirection.right) {
      message = "Interested in ${swipedProfile.name}";
    } else if (direction == CardSwiperDirection.bottom) {
      // Navigate to detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileDetailScreen(profile: swipedProfile),
        ),
      );
      // Undo the swipe to keep the card in the deck
      _cardController.undo();
      return false; // Prevent the card from being swiped away
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
      );
    }

    return true; // Allow the card to be swiped away
  }

  // Add logout handler method
  Future<void> _handleLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.darkGrey,
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.accentPink),
                ),
              ),
            ],
          ),
    );

    if (result == true) {
      // Perform logout
      await AuthService.logout();

      // Update auth provider state
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.initialize();

        // Navigate to login screen
        AppRouter.navigateToLogin(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackground,
              AppTheme.darkerPurple.withOpacity(0.8),
              AppTheme.darkBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [_buildAppBar(), Expanded(child: _buildCardStack())],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  // Navigate to profile page
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Logout',
                onPressed: _handleLogout,
              ),
            ],
          ),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.purpleGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logos/Circle_Logo.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Flinder',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              // Navigate to messages page
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryPurple),
      );
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied,
              size: 80,
              color: AppTheme.lightPurple,
            ),
            const SizedBox(height: 16),
            Text(
              'No more profiles to show',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfiles,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Reload Profiles'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: CardSwiper(
        controller: _cardController,
        cardsCount: _profiles.length,
        onSwipe: _onSwipe,
        numberOfCardsDisplayed: 3,
        backCardOffset: const Offset(0, 40),
        padding: EdgeInsets.zero,
        allowedSwipeDirection: AllowedSwipeDirection.only(
          up: false,
          down: true,
          left: true,
          right: true,
        ),
        cardBuilder: (
          context,
          index,
          horizontalThresholdPercentage,
          verticalThresholdPercentage,
        ) {
          final profile = _profiles[index];
          return ProfileCard(
            profile: profile,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileDetailScreen(profile: profile),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Add bottom nav bar for consistency with matches screen
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primaryPurple,
        unselectedItemColor: Colors.white.withOpacity(0.5),
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Matches'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(context, AppRouter.matchesRoute);
          } else if (index != 0) {
            // Show not implemented message for other tabs
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This feature is not implemented yet'),
                backgroundColor: AppTheme.primaryPurple,
              ),
            );
          }
        },
      ),
    );
  }
}
