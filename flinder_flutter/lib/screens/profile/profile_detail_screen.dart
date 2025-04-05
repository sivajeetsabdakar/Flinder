import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../constants/api_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../routes/app_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileDetailScreen extends StatelessWidget {
  final UserProfile profile;

  const ProfileDetailScreen({Key? key, required this.profile})
    : super(key: key);

  Future<void> _handleLogout(BuildContext context) async {
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
      await AuthService.logout();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();

      AppRouter.navigateToLogin(context);
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
        child: Stack(
          children: [
            // Profile content
            CustomScrollView(
              slivers: [
                // App bar with profile image
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  stretch: true,
                  backgroundColor: AppTheme.darkBackground,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildProfileImage(),
                        // Gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Name and age
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${profile.name}, ${profile.age}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPurple.withOpacity(
                                        0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.favorite,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        // Text(
                                        //   '${profile.compatibilityScore.toInt()}%',
                                        //   style: const TextStyle(
                                        //     color: Colors.white,
                                        //     fontWeight: FontWeight.bold,
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.preferences?['Occupation'] ??
                                    profile.location,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.darkGrey.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.darkGrey.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout),
                      ),
                      tooltip: 'Logout',
                      onPressed: () => _handleLogout(context),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.darkGrey.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),

                // Profile details
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bio section
                        _buildSectionTitle('About Me'),
                        const SizedBox(height: 8),
                        Text(
                          profile.bio ?? 'No bio provided',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Interests section
                        _buildSectionTitle('Interests'),
                        const SizedBox(height: 12),
                        profile.interests != null &&
                                profile.interests!.isNotEmpty
                            ? Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  profile.interests!
                                      .map(
                                        (interest) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryPurple
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.primaryPurple,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            interest,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            )
                            : Text(
                              'No interests listed',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                        const SizedBox(height: 24),

                        // Preferences section
                        _buildSectionTitle('Lifestyle Preferences'),
                        const SizedBox(height: 16),
                        _buildPreferencesList(),
                        const SizedBox(height: 32),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Not Interested',
                                onPressed: () => Navigator.pop(context),
                                type: ButtonType.secondary,
                                icon: Icons.close,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomButton(
                                text: 'Interested',
                                onPressed: () => Navigator.pop(context),
                                icon: Icons.favorite,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.1),
        BlendMode.darken,
      ),
      child:
          profile.photoUrl != null
              ? CachedNetworkImage(
                imageUrl: profile.photoUrl!,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: AppTheme.darkGrey,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: AppTheme.darkGrey,
                      child: Center(
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: AppTheme.primaryPurple.withOpacity(0.5),
                        ),
                      ),
                    ),
              )
              : Container(
                color: AppTheme.darkGrey,
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: AppTheme.primaryPurple.withOpacity(0.5),
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.lightPurple,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPreferencesList() {
    if (profile.preferences == null || profile.preferences!.isEmpty) {
      return Text(
        'No preferences provided',
        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
      );
    }

    return Column(
      children:
          profile.preferences!.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _getPreferenceIcon(entry.key),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.value.toString(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Icon _getPreferenceIcon(String preference) {
    switch (preference) {
      case 'Schedule':
        return const Icon(Icons.access_time, color: AppTheme.lightPurple);
      case 'Noise':
        return const Icon(Icons.volume_up, color: AppTheme.lightPurple);
      case 'Cooking':
        return const Icon(Icons.restaurant, color: AppTheme.lightPurple);
      case 'Diet':
        return const Icon(Icons.set_meal, color: AppTheme.lightPurple);
      case 'Smoking':
        return const Icon(Icons.smoking_rooms, color: AppTheme.lightPurple);
      case 'Alcohol':
        return const Icon(Icons.local_bar, color: AppTheme.lightPurple);
      case 'Pets':
        return const Icon(Icons.pets, color: AppTheme.lightPurple);
      case 'Cleaning':
        return const Icon(Icons.cleaning_services, color: AppTheme.lightPurple);
      case 'Guests':
        return const Icon(Icons.people, color: AppTheme.lightPurple);
      default:
        return const Icon(Icons.info, color: AppTheme.lightPurple);
    }
  }
}
