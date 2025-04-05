import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_bar_with_logout.dart';
import '../../widgets/swipe_card.dart';

class FindScreen extends StatefulWidget {
  const FindScreen({Key? key}) : super(key: key);

  @override
  _FindScreenState createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  bool _isLoading = true;
  List<UserProfile> _potentialMatches = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPotentialMatches();
  }

  Future<void> _loadPotentialMatches() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the ProfileService to get potential matches
      final matches = await ProfileService.getPotentialMatches();

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
      final token = await AuthService.getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Determine the endpoint based on the swipe direction
      final endpoint =
          isLike
              ? '${ApiConstants.baseUrl}${ApiConstants.likeEndpoint}/${profile.id}'
              : '${ApiConstants.baseUrl}${ApiConstants.dislikeEndpoint}/${profile.id}';

      log('API Call: POST $endpoint');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      log('Response Status: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode != 200) {
        log(
          'Failed to register ${isLike ? 'like' : 'dislike'}: ${response.body}',
        );
      }
    } catch (e) {
      log('Error handling swipe: $e');
      // Continue showing profiles even if like/dislike fails
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
            onPressed: _loadPotentialMatches,
            tooltip: 'Refresh potential matches',
          ),
        ],
      ),
      body: _buildBody(),
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
      onSwipeLeft: (profile) => _handleSwipe(profile, false),
      onSwipeRight: (profile) => _handleSwipe(profile, true),
    );
  }
}
