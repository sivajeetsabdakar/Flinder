import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/discover_service.dart';
import '../../widgets/app_bar_with_logout.dart';
import '../../widgets/swipe_card.dart';
import '../../routes/app_router.dart';

class FindScreen extends StatefulWidget {
  const FindScreen({Key? key}) : super(key: key);

  @override
  _FindScreenState createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  bool _isLoading = true;
  List<UserProfile> _potentialMatches = [];
  List<UserProfile> _likesReceived = [];
  String? _error;
  bool _isCheckingLikes = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    // First ensure Supabase is authenticated
    final authSuccess = await DiscoverService.ensureSupabaseAuth();
    log('Supabase auth check result: $authSuccess');

    // Then load profiles and check for likes
    _loadPotentialMatches();
    _checkForLikes();
  }

  Future<void> _checkForLikes() async {
    if (_isCheckingLikes) return;

    setState(() {
      _isCheckingLikes = true;
    });

    try {
      final likes = await DiscoverService.getLikesReceived();

      if (mounted) {
        setState(() {
          _likesReceived = likes;
          _isCheckingLikes = false;
        });
      }

      log('Found ${likes.length} users who liked the current user');
    } catch (e) {
      log('Error checking for likes: $e');
      if (mounted) {
        setState(() {
          _isCheckingLikes = false;
        });
      }
    }
  }

  Future<void> _loadPotentialMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the DiscoverService to get profiles from the discover endpoint
      final matches = await DiscoverService.getDiscoverProfiles();

      if (mounted) {
        setState(() {
          _potentialMatches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading potential matches: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load potential matches. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSwipe(UserProfile profile, bool isLike) async {
    try {
      // Record the swipe in Supabase database
      final direction = isLike ? 'left' : 'right'; // In our app, left is like
      log(
        'Recording swipe for user ${profile.name} with ID ${profile.id}, direction: $direction',
      );

      final success = await DiscoverService.recordSwipe(
        targetUserId: profile.id,
        direction: direction,
      );

      if (success) {
        log('Successfully recorded swipe in Supabase database');

        // Remove this profile from the list to prevent it from showing again in this session
        if (mounted) {
          setState(() {
            _potentialMatches.removeWhere((p) => p.id == profile.id);
          });
        }
      } else {
        log('Failed to record swipe in database');
      }
    } catch (e) {
      log('Error handling swipe: $e');
      // Continue showing profiles even if recording fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithLogout(
        title: 'Find',
        additionalActions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPotentialMatches();
              _checkForLikes();
            },
            tooltip: 'Refresh potential matches',
          ),
        ],
      ),
      body: Column(
        children: [
          // Show banner if there are likes
          if (_likesReceived.isNotEmpty) _buildLikesBanner(),

          // Main content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildLikesBanner() {
    return GestureDetector(
      onTap: () {
        // Navigate to the liked you screen (index 3 in bottom nav)
        final navigationState = Navigator.of(context);
        // Use your app's navigation method to switch to the Liked You tab
        navigationState.pushNamed(AppRouter.homeRoute, arguments: 3);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryPurple,
              AppTheme.primaryPurple.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_likesReceived.length} ${_likesReceived.length == 1 ? 'person' : 'people'} liked you!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Tap to view and respond',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPotentialMatches,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_potentialMatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No potential matches found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check back later or adjust your preferences',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPotentialMatches,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return SwipeCard(
      profiles: _potentialMatches,
      onSwipeLeft: (profile) => _handleSwipe(profile, true), // Left is like
      onSwipeRight:
          (profile) => _handleSwipe(profile, false), // Right is dislike
    );
  }
}
