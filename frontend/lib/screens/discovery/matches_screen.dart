import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/api_constants.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../widgets/app_bar_with_logout.dart';
import '../../widgets/custom_button.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late List<UserProfile> _matches;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // In a real app, this would be fetched from an API
    setState(() {
      _matches = [
        UserProfile(
          id: '1',
          name: 'Emma Watson',
          age: 28,
          location: 'London',
          roomType: 'Private',
          budget: '\$500-\$1000',
          bio:
              'I\'m looking for a quiet and tidy flatmate. I work as a software engineer and enjoy reading in my free time.',
          interests: ['Reading', 'Hiking', 'Cooking', 'Photography'],
          preferences: {
            'Schedule': 'Early bird (6AM-10PM)',
            'Noise': 'Prefer quiet environment',
            'Cooking': 'Cook often, happy to share meals',
            'Cleaning': 'Very tidy, clean weekly',
            'Occupation': 'Software Engineer',
          },
          photoUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
        ),
        UserProfile(
          id: '2',
          name: 'Michael Johnson',
          age: 30,
          location: 'New York',
          roomType: 'Shared',
          budget: '\$1000-\$1500',
          bio:
              'Graphic designer looking for a creative space to share. I\'m friendly, respectful, and enjoy good conversations.',
          interests: ['Art', 'Movies', 'Travel', 'Music'],
          preferences: {
            'Schedule': 'Night owl (11AM-2AM)',
            'Noise': 'Moderate, enjoy music',
            'Guests': 'Occasionally have friends over',
            'Pets': 'Love animals, have none currently',
            'Occupation': 'Graphic Designer',
          },
          photoUrl:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
        ),
        UserProfile(
          id: '3',
          name: 'Sophia Chen',
          age: 26,
          location: 'San Francisco',
          roomType: 'Studio',
          budget: '\$1500+',
          bio:
              'Medical student looking for a quiet place. I\'m organized, clean, and respectful of shared spaces.',
          interests: ['Fitness', 'Cooking', 'Reading', 'Yoga'],
          preferences: {
            'Schedule': 'Early bird (5AM-10PM)',
            'Noise': 'Quiet environment for studying',
            'Cleaning': 'Very tidy, clean regularly',
            'Diet': 'Vegetarian, but don\'t mind others cooking meat',
            'Occupation': 'Medical Student',
          },
          photoUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Matches',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
      ),
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
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryPurple,
                  ),
                )
                : _matches.isEmpty
                ? _buildEmptyState()
                : _buildMatchesList(),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: 80,
              color: AppTheme.primaryPurple.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No matches yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Keep swiping to find your perfect flatmate match!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Find More Matches',
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRouter.homeRoute);
              },
              icon: Icons.search,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        return _buildMatchCard(match);
      },
    );
  }

  Widget _buildMatchCard(UserProfile match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRouter.profileDetailRoute,
            arguments: match,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(match),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${match.name}, ${match.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: AppTheme.lightPurple,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(match.location.length % 30) + 70}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.preferences?['Occupation'] ?? 'Professional',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (match.interests != null &&
                        match.interests!.isNotEmpty) ...{
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            match.interests!.take(3).map((interest) {
                              return _buildInterestChip(interest);
                            }).toList(),
                      ),
                    },
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Message',
                            onPressed: () {
                              // Navigate to messaging screen (not implemented)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Messaging not implemented yet',
                                  ),
                                  backgroundColor: AppTheme.primaryPurple,
                                ),
                              );
                            },
                            type: ButtonType.secondary,
                            icon: Icons.chat_bubble_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'View Profile',
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRouter.profileDetailRoute,
                                arguments: match,
                              );
                            },
                            icon: Icons.person_outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(UserProfile match) {
    return Hero(
      tag: 'avatar_${match.id}',
      child: Material(
        elevation: 4,
        shadowColor: AppTheme.primaryPurple.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        child:
            match.photoUrl != null
                ? CachedNetworkImage(
                  imageUrl: match.photoUrl!,
                  width: 100,
                  height: 130,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        width: 100,
                        height: 130,
                        decoration: BoxDecoration(
                          color: AppTheme.darkGrey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        width: 100,
                        height: 130,
                        decoration: BoxDecoration(
                          color: AppTheme.darkGrey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.error, color: Colors.white),
                      ),
                  imageBuilder:
                      (context, imageProvider) => Container(
                        width: 100,
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                )
                : Container(
                  width: 100,
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppTheme.darkGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white70,
                    size: 40,
                  ),
                ),
      ),
    );
  }

  Widget _buildInterestChip(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        interest,
        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
      ),
    );
  }

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
        currentIndex: 1,
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
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRouter.homeRoute);
          } else if (index != 1) {
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
