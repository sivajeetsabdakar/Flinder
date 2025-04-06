import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_profile_service.dart';
import './interests_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({Key? key}) : super(key: key);

  @override
  _ProfileCompletionScreenState createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  // Form keys for each step
  final _criticalFormKey = GlobalKey<FormState>();
  final _nonCriticalFormKey = GlobalKey<FormState>();
  final _discoveryFormKey = GlobalKey<FormState>();

  // Controllers
  final _cityController = TextEditingController();
  final _ageController = TextEditingController();

  // Current step
  int _currentStep = 0;
  bool _isLoading = false;

  // Critical preferences
  List<String> _roomTypes = ['Private', 'Shared', 'Studio', 'Any'];
  List<String> _budgetRanges = [
    'Under \$500',
    '\$500-\$1000',
    '\$1000-\$1500',
    '\$1500+',
  ];
  String _selectedRoomType = 'Private';
  String _selectedBudgetRange = '\$500-\$1000';

  // Non-critical preferences
  List<String> _schedules = ['Early Riser', 'Night Owl', 'Flexible'];
  List<String> _noiseLevels = ['Silent', 'Moderate', 'Loud'];
  List<String> _cleaningHabits = ['Very Clean', 'Average', 'Messy'];
  String _selectedSchedule = 'Flexible';
  String _selectedNoiseLevel = 'Moderate';
  String _selectedCleaningHabits = 'Average';

  // Discovery preferences
  RangeValues _ageRange = const RangeValues(18, 35);
  double _maxDistance = 15;
  bool _showMeToOthers = true;

  // User interests
  List<String> _selectedInterests = [];

  // Method to update selected interests
  void _updateSelectedInterests(List<String> interests) {
    setState(() {
      _selectedInterests = interests;
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _ageController.dispose();
    super.dispose();
  }

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
      await AuthService.logout();
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.initialize();
        AppRouter.navigateToLogin(context);
      }
    }
  }

  // Validate current step and move to next step
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _criticalFormKey.currentState?.validate() ?? false;
      case 1:
        return _nonCriticalFormKey.currentState?.validate() ?? false;
      case 2:
        return _discoveryFormKey.currentState?.validate() ?? false;
      case 3:
        // Interests step - validate there's at least one selection
        return _selectedInterests.isNotEmpty;
      default:
        return false;
    }
  }

  // Handle continue button press
  void _handleContinue() {
    // Validate the current step's form
    if (!_validateCurrentStep()) {
      return;
    }

    setState(() {
      if (_currentStep < 3) {
        _currentStep++;
      } else {
        // Last step, complete profile
        _completeProfile();
      }
    });
  }

  // Handle cancel button press
  void _handleCancel() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  // Complete profile and navigate to main screen
  Future<void> _completeProfile() async {
    // Validate the form first
    if (!_validateCurrentStep()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('ProfileCompletionScreen - Completing profile');

      // Update profile completion status locally
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser != null) {
        currentUser.isProfileCompleted = true;

        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(currentUser.toJson()));

        // Double check it was saved correctly
        final savedUserJson = prefs.getString('user');
        if (savedUserJson != null) {
          final savedUserData = jsonDecode(savedUserJson);
          final savedProfileCompleted =
              savedUserData['isProfileCompleted'] ?? false;
          print(
            'ProfileCompletionScreen - Profile completion status after save: $savedProfileCompleted',
          );

          if (!savedProfileCompleted) {
            // Force direct update if not saved correctly
            print(
              'ProfileCompletionScreen - Forcing direct update of isProfileCompleted',
            );
            Map<String, dynamic> userData = jsonDecode(savedUserJson);
            userData['isProfileCompleted'] = true;
            await prefs.setString('user', jsonEncode(userData));
          }
        }
      }

      // Also update using UserProfileService to ensure consistency
      await UserProfileService.updateProfileStatus(true);

      print(
        'ProfileCompletionScreen - Profile marked as completed, navigating to main screen',
      );

      if (mounted) {
        // Navigate to the main screen after profile completion
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.mainRoute,
          (route) => false,
        );
      }
    } catch (e) {
      print('ProfileCompletionScreen - ERROR: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
          child: Stack(
            children: [
              // Logout button in top-right
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Logout',
                  onPressed: _handleLogout,
                ),
              ),

              // Main content
              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 8),
                    child: Text(
                      'Complete Your Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Custom step indicator
                  _buildCustomStepIndicator(),

                  // Content area with step content
                  Expanded(child: _buildStepContent()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step 1: Critical Preferences (Location & Budget)
  Widget _buildCriticalStep() {
    return Form(
      key: _criticalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let us know about your location and budget preferences.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // City input
          _buildSectionTitle('Where are you looking for a flatmate?'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
              hintText: 'Enter city',
              prefixIcon: const Icon(
                Icons.location_city,
                color: AppTheme.lightPurple,
              ),
              fillColor: AppTheme.darkGrey.withOpacity(0.7),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.primaryPurple,
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a city';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Room type selection
          _buildSectionTitle('What type of room are you looking for?'),
          const SizedBox(height: 12),
          _buildChoiceContainer(_roomTypes, _selectedRoomType, (value) {
            setState(() {
              _selectedRoomType = value;
            });
          }),
          const SizedBox(height: 24),

          // Budget range selection
          _buildSectionTitle('What\'s your budget range?'),
          const SizedBox(height: 12),
          _buildChoiceContainer(_budgetRanges, _selectedBudgetRange, (value) {
            setState(() {
              _selectedBudgetRange = value;
            });
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Step 2: Non-Critical Preferences (Lifestyle)
  Widget _buildNonCriticalStep() {
    return Form(
      key: _nonCriticalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about your lifestyle preferences to find compatible flatmates.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // Schedule preference
          _buildSectionTitle('What\'s your daily schedule?'),
          const SizedBox(height: 12),
          _buildChoiceContainer(_schedules, _selectedSchedule, (value) {
            setState(() {
              _selectedSchedule = value;
            });
          }),
          const SizedBox(height: 24),

          // Noise level preference
          _buildSectionTitle('What noise level do you prefer?'),
          const SizedBox(height: 12),
          _buildChoiceContainer(_noiseLevels, _selectedNoiseLevel, (value) {
            setState(() {
              _selectedNoiseLevel = value;
            });
          }),
          const SizedBox(height: 24),

          // Cleaning habits
          _buildSectionTitle('How would you describe your cleaning habits?'),
          const SizedBox(height: 12),
          _buildChoiceContainer(_cleaningHabits, _selectedCleaningHabits, (
            value,
          ) {
            setState(() {
              _selectedCleaningHabits = value;
            });
          }),
          const SizedBox(height: 24),

          // Age input
          _buildSectionTitle('How old are you?'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _ageController,
            decoration: InputDecoration(
              hintText: 'Enter your age',
              prefixIcon: const Icon(Icons.cake, color: AppTheme.lightPurple),
              fillColor: AppTheme.darkGrey.withOpacity(0.7),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.primaryPurple,
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your age';
              }
              final age = int.tryParse(value);
              if (age == null || age < 18 || age > 100) {
                return 'Please enter a valid age between 18 and 100';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Step 3: Discovery Preferences (Matching Settings)
  Widget _buildDiscoveryStep() {
    return Form(
      key: _discoveryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configure your discovery settings for optimal flatmate matching.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // Age range preference
          _buildSectionTitle('Preferred age range for potential flatmates'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkGrey.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_ageRange.start.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'to',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_ageRange.end.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.primaryPurple,
                    inactiveTrackColor: AppTheme.primaryPurple.withOpacity(0.2),
                    thumbColor: AppTheme.lightPurple,
                    overlayColor: AppTheme.primaryPurple.withOpacity(0.1),
                    valueIndicatorColor: AppTheme.primaryPurple,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  child: RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 65,
                    divisions: 47,
                    labels: RangeLabels(
                      '${_ageRange.start.toInt()}',
                      '${_ageRange.end.toInt()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _ageRange = values;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Maximum distance
          _buildSectionTitle('Maximum distance (km)'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkGrey.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_maxDistance.toInt()} km',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.primaryPurple,
                    inactiveTrackColor: AppTheme.primaryPurple.withOpacity(0.2),
                    thumbColor: AppTheme.lightPurple,
                    overlayColor: AppTheme.primaryPurple.withOpacity(0.1),
                    valueIndicatorColor: AppTheme.primaryPurple,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  child: Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_maxDistance.toInt()} km',
                    onChanged: (value) {
                      setState(() {
                        _maxDistance = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Show me to others switch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkGrey.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: SwitchListTile(
              title: const Text(
                'Show Me to Others',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Turn off to hide your profile from others but still see potential matches.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              value: _showMeToOthers,
              activeColor: AppTheme.primaryPurple,
              onChanged: (value) {
                setState(() {
                  _showMeToOthers = value;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Step 4: Interests Selection
  Widget _buildInterestsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your interests to match with like-minded flatmates.',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
        ),
        const SizedBox(height: 24),

        // Card to show selected interests or prompt to select
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkGrey.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryPurple.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Interests',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.edit,
                      color: AppTheme.primaryPurple,
                      size: 16,
                    ),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      // Navigate to interests selection screen
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => InterestsSelectionScreen(
                                initialInterests: _selectedInterests,
                                maxSelections: 10,
                                isOnboarding: true,
                              ),
                        ),
                      );

                      // Update interests if returned
                      if (result != null && result is List<String>) {
                        _updateSelectedInterests(result);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Display selected interests or prompt
              _selectedInterests.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.interests,
                            size: 48,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap "Edit" to select your interests',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                  : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _selectedInterests
                            .map(
                              (interest) => Chip(
                                label: Text(
                                  interest,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                backgroundColor: AppTheme.primaryPurple
                                    .withOpacity(0.7),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            )
                            .toList(),
                  ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Help text
        Text(
          'Your interests help us match you with compatible flatmates. You\'ll be able to update them later.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  // Helper to build section titles
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Helper to build choice containers
  Widget _buildChoiceContainer(
    List<String> options,
    String selectedOption,
    Function(String) onSelected,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final optionWidth =
        screenWidth < 360 ? (screenWidth - 76) / 2 : screenWidth * 0.4;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children:
            options.map((option) {
              final isSelected = selectedOption == option;
              return InkWell(
                onTap: () => onSelected(option),
                child: Container(
                  width: optionWidth,
                  height: 50,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppTheme.primaryPurple
                            : AppTheme.darkBackground.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppTheme.lightPurple
                              : AppTheme.primaryPurple.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: AppTheme.primaryPurple.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        color:
                            isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.8),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // Helper to build step indicators
  Widget _buildStepIndicator(String label, int index) {
    final bool isActive = _currentStep >= index;
    final bool isCurrent = _currentStep == index;

    return GestureDetector(
      onTap: () {
        // Only allow moving to previous or current steps
        if (_currentStep >= index) {
          setState(() {
            _currentStep = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 13,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color:
                    isCurrent
                        ? AppTheme.primaryPurple
                        : (isActive
                            ? AppTheme.lightPurple.withOpacity(0.5)
                            : Colors.white.withOpacity(0.3)),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isActive
                          ? AppTheme.primaryPurple
                          : Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child:
                  isCurrent
                      ? const Center(
                        child: Icon(Icons.circle, size: 6, color: Colors.white),
                      )
                      : isActive
                      ? const Center(
                        child: Icon(Icons.check, size: 10, color: Colors.white),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build step divider
  Widget _buildStepDivider() {
    return Container(
      width: 30,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white.withOpacity(0.3),
    );
  }

  // Custom step indicator
  Container _buildCustomStepIndicator() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment:
              MediaQuery.of(context).size.width > 360
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
          children: [
            _buildStepIndicator('Basics', 0),
            _buildStepDivider(),
            _buildStepIndicator('Lifestyle', 1),
            _buildStepDivider(),
            _buildStepIndicator('Matching', 2),
            _buildStepDivider(),
            _buildStepIndicator('Interests', 3),
          ],
        ),
      ),
    );
  }

  // Helper to build step content
  Widget _buildStepContent() {
    Widget content;

    switch (_currentStep) {
      case 0:
        content = _buildCriticalStep();
        break;
      case 1:
        content = _buildNonCriticalStep();
        break;
      case 2:
        content = _buildDiscoveryStep();
        break;
      case 3:
        content = _buildInterestsStep();
        break;
      default:
        content = Container();
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: content,
            ),
          ),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppTheme.primaryPurple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: TextStyle(color: AppTheme.primaryPurple),
                    ),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppTheme.purpleGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              _currentStep == 3 ? 'Complete' : 'Continue',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
