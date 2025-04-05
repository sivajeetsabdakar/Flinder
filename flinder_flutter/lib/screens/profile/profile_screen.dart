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
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Profile completion indicator
                if (_user != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
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
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
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
                                        : Colors.orange,
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
                                          : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Profile picture
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
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
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.email ?? '',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),

                // Location
                if (_profile != null && _profile!.location.city.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _profile!.location.neighborhood != null
                              ? '${_profile!.location.city}, ${_profile!.location.neighborhood}'
                              : _profile!.location.city,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bio section
          if (_profile != null && _profile!.bio.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.1),
                    AppTheme.lightPurple.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: AppTheme.primaryPurple,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About Me',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profile!.bio,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (_profile!.generatedDescription != null &&
                      _profile!.generatedDescription!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryPurple.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Generated Summary',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _profile!.generatedDescription!,
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Interests section
          if (_profile != null && _profile!.interests.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.interests,
                        color: AppTheme.primaryPurple,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Interests',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _profile!.interests.map((interest) {
                          // Generate a consistent color based on the interest string
                          final int hashCode = interest.hashCode;
                          final List<Color> colors = [
                            AppTheme.primaryPurple.withOpacity(0.8),
                            Colors.blue.withOpacity(0.8),
                            Colors.teal.withOpacity(0.8),
                            Colors.amber.withOpacity(0.8),
                            Colors.pink.withOpacity(0.8),
                          ];
                          final Color chipColor =
                              colors[hashCode % colors.length];

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  chipColor.withOpacity(0.7),
                                  chipColor.withOpacity(0.5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: chipColor.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              interest,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Housing preferences
          if (_profile != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.home_work,
                        color: AppTheme.primaryPurple,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Housing Preferences',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Budget preference
                  _buildPreferenceItem(
                    icon: Icons.attach_money,
                    title: 'Budget',
                    subtitle:
                        '${_profile!.budget.currency} ${_profile!.budget.min} - ${_profile!.budget.max}',
                  ),

                  // Room preference
                  _buildPreferenceItem(
                    icon: Icons.home,
                    title: 'Room Type',
                    subtitle: _formatRoomPreference(_profile!.roomPreference),
                  ),

                  // Move-in date
                  _buildPreferenceItem(
                    icon: Icons.calendar_today,
                    title: 'Move-in Date',
                    subtitle: _formatMoveInDate(_profile!.moveInDate),
                  ),

                  // Lease duration
                  _buildPreferenceItem(
                    icon: Icons.timelapse,
                    title: 'Lease Duration',
                    subtitle: _formatLeaseDuration(_profile!.leaseDuration),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Lifestyle section
          if (_profile != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mood, color: AppTheme.primaryPurple, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Lifestyle',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Schedule
                  _buildPreferenceItem(
                    icon: Icons.schedule,
                    title: 'Schedule',
                    subtitle: _formatLifestylePreference(
                      _profile!.lifestyle.schedule,
                    ),
                  ),

                  // Noise level
                  _buildPreferenceItem(
                    icon: Icons.volume_up,
                    title: 'Noise Level',
                    subtitle: _formatLifestylePreference(
                      _profile!.lifestyle.noiseLevel,
                    ),
                  ),

                  // Smoking
                  _buildPreferenceItem(
                    icon: Icons.smoking_rooms,
                    title: 'Smoking',
                    subtitle: _formatLifestylePreference(
                      _profile!.lifestyle.smoking,
                    ),
                  ),

                  // Pets
                  _buildPreferenceItem(
                    icon: Icons.pets,
                    title: 'Pets',
                    subtitle: _formatLifestylePreference(
                      _profile!.lifestyle.pets,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Languages section
          if (_profile != null && _profile!.languages.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.translate,
                        color: AppTheme.primaryPurple,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Languages',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _profile!.languages.map((language) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.lightPurple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryPurple.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.language,
                                  size: 16,
                                  color: AppTheme.primaryPurple,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  language,
                                  style: TextStyle(
                                    color: AppTheme.primaryPurple,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),

          // Buffer space at the bottom
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightGrey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryPurple, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  String _formatLeaseDuration(String duration) {
    switch (duration) {
      case 'short_term':
        return 'Short term (< 6 months)';
      case 'long_term':
        return 'Long term (> 6 months)';
      case 'flexible':
        return 'Flexible';
      default:
        return duration.replaceAll('_', ' ').capitalize();
    }
  }

  String _formatLifestylePreference(String preference) {
    return preference.replaceAll('_', ' ').capitalize();
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return this
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }
}
