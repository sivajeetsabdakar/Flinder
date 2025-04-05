import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/swipe_card.dart';
import '../widgets/app_bar_with_logout.dart';

class FindScreen extends StatefulWidget {
  const FindScreen({Key? key}) : super(key: key);

  @override
  _FindScreenState createState() => _FindScreenState();
}

class _FindScreenState extends State<FindScreen> {
  List<UserProfile> _potentialMatches = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPotentialMatches();
  }

  Future<void> _loadPotentialMatches() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.discoverEndpoint}'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true &&
            responseData['profiles'] != null) {
          final List<dynamic> profilesData = responseData['profiles'];

          final profiles =
              profilesData.map((data) {
                // Map the API response to our UserProfile model
                final photoUrl =
                    data['profilePictures'] != null &&
                            data['profilePictures'].isNotEmpty
                        ? data['profilePictures'][0]['url']
                        : null;

                return UserProfile(
                  id: data['userId'] ?? '',
                  name: data['name'] ?? 'Unknown',
                  age: data['age'] ?? 25,
                  location:
                      data['location'] != null
                          ? data['location']['city']
                          : 'Unknown',
                  roomType: _formatRoomType(data),
                  budget: _formatBudget(data),
                  bio: data['bio'],
                  interests:
                      data['interests'] != null
                          ? List<String>.from(data['interests'])
                          : null,
                  photoUrl: photoUrl,
                  preferences: {
                    if (data['lifestyle'] != null)
                      'Schedule': _formatLifestyleSchedule(
                        data['lifestyle']['schedule'],
                      ),
                    if (data['lifestyle'] != null)
                      'Cleaning': _formatCleaningHabits(
                        data['lifestyle']['cleaningHabits'],
                      ),
                  },
                );
              }).toList();

          setState(() {
            _potentialMatches = profiles;
            _isLoading = false;
          });
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load profiles');
        }
      } else {
        throw Exception('Failed to load profiles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading profiles: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();

        // Temporarily fall back to dummy data when testing
        _potentialMatches = UserProfile.getDummyProfiles();
      });
    }
  }

  // Helper methods to format API response data
  String _formatRoomType(dynamic data) {
    if (data['preferences'] == null ||
        data['preferences']['critical'] == null ||
        data['preferences']['critical']['roomType'] == null) {
      return 'Any';
    }

    final roomType = data['preferences']['critical']['roomType'];
    switch (roomType) {
      case 'private':
        return 'Private Room';
      case 'shared':
        return 'Shared Room';
      case 'studio':
        return 'Studio';
      default:
        return 'Any';
    }
  }

  String _formatBudget(dynamic data) {
    if (data['preferences'] == null ||
        data['preferences']['critical'] == null ||
        data['preferences']['critical']['budget'] == null) {
      return 'Flexible';
    }

    final budget = data['preferences']['critical']['budget'];
    if (budget['min'] != null && budget['max'] != null) {
      return '\$${budget['min']}-\$${budget['max']}';
    }
    return 'Flexible';
  }

  String _formatLifestyleSchedule(String? schedule) {
    if (schedule == null) return 'Flexible';

    switch (schedule) {
      case 'early_riser':
        return 'Early Riser';
      case 'night_owl':
        return 'Night Owl';
      default:
        return 'Flexible';
    }
  }

  String _formatCleaningHabits(String? cleaningHabits) {
    if (cleaningHabits == null) return 'Average';

    switch (cleaningHabits) {
      case 'very_clean':
        return 'Very Clean';
      case 'average':
        return 'Average';
      case 'messy':
        return 'Messy';
      default:
        return 'Average';
    }
  }

  Future<void> _handleLike(UserProfile profile) async {
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.likeEndpoint}'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode({'userId': profile.id}),
      );

      if (response.statusCode == 200) {
        print('Successfully liked profile: ${profile.name}');

        // Check if it's a match and show match dialog
        final responseData = jsonDecode(response.body);
        if (responseData['isMatch'] == true) {
          if (mounted) {
            _showMatchDialog(profile);
          }
        }
      } else {
        print('Error liking profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error liking profile: $e');
    }
  }

  Future<void> _handleDislike(UserProfile profile) async {
    try {
      final token = await AuthService.getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.dislikeEndpoint}'),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode({'userId': profile.id}),
      );

      if (response.statusCode == 200) {
        print('Successfully passed on profile: ${profile.name}');
      } else {
        print('Error passing on profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error passing on profile: $e');
    }
  }

  void _showMatchDialog(UserProfile profile) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.darkGrey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'It\'s a Match!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text(
                  'You and ${profile.name} like each other!',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryPurple, AppTheme.accentPink],
                    ),
                  ),
                  child: Center(
                    child:
                        profile.photoUrl != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.network(
                                profile.photoUrl!,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            )
                            : Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white.withOpacity(0.9),
                            ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.lightPurple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Continue Swiping'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to chat with this user
                        // This would be implemented in a real app
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Send Message'),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithLogout(
        title: 'FLIND',
        additionalActions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPotentialMatches,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.darkerPurple, AppTheme.darkBackground],
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.lightPurple),
                )
                : _hasError
                ? _buildErrorScreen()
                : _potentialMatches.isEmpty
                ? _buildEmptyScreen()
                : _buildSwipeCards(),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.accentPink.withOpacity(0.8),
          ),
          const SizedBox(height: 24),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.purpleGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _loadPotentialMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 100,
            color: AppTheme.lightPurple.withOpacity(0.7),
          ),
          const SizedBox(height: 32),
          const Text(
            'No More Profiles',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'We\'ve run out of potential matches for now. Check back later!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.purpleGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _loadPotentialMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Find More',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeCards() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Show back card with next profile if available
          if (_potentialMatches.length > 1)
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              bottom: 10,
              child: Transform.scale(
                scale: 0.9,
                child: Opacity(
                  opacity: 0.6,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppTheme.darkGrey.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),

          // // Show the current profile card
          // _potentialMatches.isNotEmpty
          //     ? SwipeCard(

          //       profile: _potentialMatches.first,
          //       onLike: () {
          //         _handleLike(_potentialMatches.first);
          //         setState(() {
          //           if (_potentialMatches.isNotEmpty) {
          //             _potentialMatches.removeAt(0);
          //           }
          //         });
          //       },
          //       onDislike: () {
          //         _handleDislike(_potentialMatches.first);
          //         setState(() {
          //           if (_potentialMatches.isNotEmpty) {
          //             _potentialMatches.removeAt(0);
          //           }
          //         });

          //       },
          //     )
          _buildEmptyScreen(),

          // Instructions text at bottom
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.darkerPurple.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Swipe card to see next profile',
                style: TextStyle(
                  color: AppTheme.lightPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
