import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../models/user_model.dart';
import '../../models/profile_model.dart';
import '../../constants/api_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_with_logout.dart';
import '../../routes/app_router.dart';
import '../../main.dart'
    show navigatorObserver; // Import just the navigatorObserver
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  UserModel? _user;
  ProfileModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use the navigatorObserver from main.dart
    navigatorObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    // Use the navigatorObserver from main.dart
    navigatorObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Reload profile when coming back to this screen
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user data
      final user = await AuthService.getCurrentUser();

      // Load profile data
      final profile = await ProfileService.getCurrentProfile();

      if (mounted) {
        setState(() {
          _user = user;
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithLogout(
        title: 'Your Profile',
        additionalActions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              AppRouter.navigateToEditProfile(context);
              // We can't reload immediately - we need to listen for navigation completion
              // This will be handled in the didPopNext method
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorScreen()
              : _user == null
              ? _buildNoUserScreen()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
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

  Widget _buildNoUserScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Unable to load profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadUserProfile,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with avatar and basic info
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkerPurple,
                  AppTheme.darkerPurple.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Profile completion indicator
                if (_user != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _user!.isProfileCompleted == true
                                  ? Colors.green.withOpacity(0.2)
                                  : AppTheme.accentPink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _user!.isProfileCompleted == true
                                    ? Colors.green.withOpacity(0.5)
                                    : AppTheme.accentPink.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _user!.isProfileCompleted == true
                                  ? Icons.check_circle
                                  : Icons.warning_amber_rounded,
                              size: 16,
                              color:
                                  _user!.isProfileCompleted == true
                                      ? Colors.green
                                      : AppTheme.accentPink,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _user!.isProfileCompleted == true
                                  ? 'Complete'
                                  : 'Incomplete',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    _user!.isProfileCompleted == true
                                        ? Colors.green
                                        : AppTheme.accentPink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),

                // Profile picture
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.lightPurple,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child:
                          _profile != null &&
                                  _profile!.profilePictures.isNotEmpty
                              ? CircleAvatar(
                                radius: 60,
                                backgroundImage: NetworkImage(
                                  _profile!.profilePictures
                                      .firstWhere(
                                        (pic) => pic.isPrimary,
                                        orElse:
                                            () =>
                                                _profile!.profilePictures.first,
                                      )
                                      .url,
                                ),
                              )
                              : CircleAvatar(
                                radius: 60,
                                backgroundColor: AppTheme.primaryPurple,
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // User name and email
                Text(
                  _user?.name ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.email ?? 'No email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),

                if (_profile != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryPurple,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _profile!.roomPreference,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bio section
          _buildSection(
            title: 'Bio',
            icon: Icons.person_outline,
            child: Text(
              _profile?.bio.isNotEmpty == true
                  ? _profile!.bio
                  : 'No bio added yet. Add a bio to tell others about yourself.',
              style: TextStyle(
                fontSize: 14,
                color:
                    _profile?.bio.isNotEmpty == true
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Preferences section
          _buildSection(
            title: 'Preferences',
            icon: Icons.tune,
            child: _buildPreferencesList(),
          ),

          const SizedBox(height: 16),

          // Interests section
          _buildSection(
            title: 'Interests',
            icon: Icons.interests,
            child: _buildInterestsList(),
          ),

          const SizedBox(height: 24),

          // Actions section
          _buildActionsSection(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryPurple),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.mediumGrey),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPreferencesList() {
    if (_profile == null) {
      return const Text(
        'No preferences set yet.',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      );
    }

    // Extract preferences to display
    final List<Map<String, String>> preferenceItems = [];

    // Add location if available
    if (_profile!.location.city.isNotEmpty) {
      preferenceItems.add({
        'icon': 'location_on',
        'label': 'Location',
        'value': _profile!.location.city,
      });
    }

    // Add budget if available
    if (_profile!.budget.min > 0 && _profile!.budget.max > 0) {
      preferenceItems.add({
        'icon': 'account_balance_wallet',
        'label': 'Budget',
        'value':
            '${_profile!.budget.currency} ${_profile!.budget.min}-${_profile!.budget.max}',
      });
    }

    // Add room type if available
    if (_profile!.roomPreference.isNotEmpty) {
      preferenceItems.add({
        'icon': 'hotel',
        'label': 'Room Type',
        'value': _formatRoomPreference(_profile!.roomPreference),
      });
    }

    // Add move-in date
    if (_profile!.moveInDate.isNotEmpty) {
      preferenceItems.add({
        'icon': 'calendar_today',
        'label': 'Move-in Date',
        'value': _formatMoveInDate(_profile!.moveInDate),
      });
    }

    if (preferenceItems.isEmpty) {
      return const Text(
        'No preferences set yet.',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      );
    }

    return Column(
      children:
          preferenceItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconData(item['icon'] ?? ''),
                      color: AppTheme.lightPurple,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['label'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        item['value'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildInterestsList() {
    if (_profile == null || _profile!.interests.isEmpty) {
      return const Text(
        'No interests added yet.',
        style: TextStyle(color: Colors.white70, fontSize: 14),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _profile!.interests.map((interest) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                interest,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.edit,
          label: 'Edit Profile',
          onTap: () {
            AppRouter.navigateToEditProfile(context);
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.apartment,
          label: 'My Applications',
          onTap: () {
            AppRouter.navigateToMyApplications(context);
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.settings,
          label: 'Account Settings',
          onTap: () {
            // TODO: Navigate to settings
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.help_outline,
          label: 'Help & Support',
          onTap: () {
            // TODO: Navigate to help
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'location_on':
        return Icons.location_on;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'hotel':
        return Icons.hotel;
      case 'calendar_today':
        return Icons.calendar_today;
      default:
        return Icons.circle;
    }
  }

  String _formatRoomPreference(String preference) {
    switch (preference) {
      case 'private':
        return 'Private Room';
      case 'shared':
        return 'Shared Room';
      case 'studio':
        return 'Studio Apartment';
      case 'any':
        return 'Any Room Type';
      default:
        return preference.replaceAll('_', ' ').capitalize();
    }
  }

  String _formatMoveInDate(String moveInDate) {
    switch (moveInDate) {
      case 'immediate':
        return 'As soon as possible';
      case 'next_month':
        return 'Next month';
      case 'flexible':
        return 'Flexible';
      default:
        // Check if it's a date string
        if (moveInDate.contains('-')) {
          try {
            final date = DateTime.parse(moveInDate);
            return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          } catch (_) {
            return moveInDate;
          }
        }
        return moveInDate;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
