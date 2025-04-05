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
      default:
        return false;
    }
  }

  // Handle continue button press
  void _handleContinue() {
    if (_validateCurrentStep()) {
      setState(() {
        if (_currentStep < 2) {
          _currentStep++;
        } else {
          _completeProfile();
        }
      });
    }
  }

  // Handle cancel button press
  void _handleCancel() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  // Complete profile and navigate to matches screen
  Future<void> _completeProfile() async {
    // Validate the form first
    if (!_validateCurrentStep()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('ProfileCompletionScreen - Starting profile completion process');

      // Check if user is logged in
      final currentUser = await AuthService.getCurrentUser();
      if (currentUser == null) {
        print(
          'ProfileCompletionScreen - No logged in user found, attempting to use auth status',
        );

        // Check if user is authenticated even if the model is not found
        final isAuth = await AuthService.isAuthenticated();
        if (!isAuth) {
          throw Exception('You need to be logged in to complete your profile');
        }
      } else {
        print('ProfileCompletionScreen - User found: ${currentUser.email}');
      }

      // Validate that necessary fields are entered
      if (_cityController.text.isEmpty) {
        throw Exception('Please enter a city');
      }

      if (_ageController.text.isEmpty) {
        throw Exception('Please enter your age');
      }

      final age = int.tryParse(_ageController.text);
      if (age == null || age < 18 || age > 100) {
        throw Exception('Please enter a valid age between 18 and 100');
      }

      print(
        'ProfileCompletionScreen - All fields validated, saving preferences',
      );

      // Save preferences to Supabase
      final success = await UserProfileService.savePreferences(
        city: _cityController.text,
        roomType: _selectedRoomType,
        budgetRange: _selectedBudgetRange,
        schedule: _selectedSchedule,
        noiseLevel: _selectedNoiseLevel,
        cleaningHabits: _selectedCleaningHabits,
        age: age,
        ageRange: _ageRange,
        maxDistance: _maxDistance,
        showMeToOthers: _showMeToOthers,
      );

      if (!success) {
        throw Exception('Failed to save preferences');
      }

      print(
        'ProfileCompletionScreen - Preferences saved successfully, navigating to main screen',
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
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                    child: Text(
                      'Complete Your Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Stepper with 3 steps
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppTheme.primaryPurple,
                          background: AppTheme.darkGrey,
                        ),
                      ),
                      child: Stepper(
                        type: StepperType.horizontal,
                        physics: const ScrollPhysics(),
                        currentStep: _currentStep,
                        controlsBuilder: (context, details) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Row(
                              children: [
                                if (_currentStep > 0)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: details.onStepCancel,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        side: BorderSide(
                                          color: AppTheme.primaryPurple,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Back',
                                        style: TextStyle(
                                          color: AppTheme.primaryPurple,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_currentStep > 0) const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: AppTheme.purpleGradient,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryPurple
                                              .withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading
                                              ? null
                                              : details.onStepContinue,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child:
                                          _isLoading
                                              ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                              : Text(
                                                _currentStep == 2
                                                    ? 'Complete'
                                                    : 'Continue',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onStepContinue: _handleContinue,
                        onStepCancel: _handleCancel,
                        steps: <Step>[
                          // Step 1: Critical Preferences (Location & Budget)
                          Step(
                            title: const Text(
                              'Basics',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            isActive: _currentStep >= 0,
                            state:
                                _currentStep > 0
                                    ? StepState.complete
                                    : StepState.indexed,
                            content: _buildCriticalStep(),
                          ),
                          // Step 2: Non-Critical Preferences (Lifestyle)
                          Step(
                            title: const Text(
                              'Lifestyle',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            isActive: _currentStep >= 1,
                            state:
                                _currentStep > 1
                                    ? StepState.complete
                                    : StepState.indexed,
                            content: _buildNonCriticalStep(),
                          ),
                          // Step 3: Discovery Preferences (Matching Settings)
                          Step(
                            title: const Text(
                              'Matching',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            isActive: _currentStep >= 2,
                            state:
                                _currentStep > 2
                                    ? StepState.complete
                                    : StepState.indexed,
                            content: _buildDiscoveryStep(),
                          ),
                        ],
                      ),
                    ),
                  ),
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
      child: SingleChildScrollView(
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
          ],
        ),
      ),
    );
  }

  // Step 2: Non-Critical Preferences (Lifestyle)
  Widget _buildNonCriticalStep() {
    return Form(
      key: _nonCriticalFormKey,
      child: SingleChildScrollView(
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
          ],
        ),
      ),
    );
  }

  // Step 3: Discovery Preferences (Matching Settings)
  Widget _buildDiscoveryStep() {
    return Form(
      key: _discoveryFormKey,
      child: SingleChildScrollView(
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
              padding: const EdgeInsets.all(20),
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
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_ageRange.start.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'to',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_ageRange.end.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primaryPurple,
                      inactiveTrackColor: AppTheme.primaryPurple.withOpacity(
                        0.2,
                      ),
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
            const SizedBox(height: 24),

            // Maximum distance
            _buildSectionTitle('Maximum distance (km)'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
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
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_maxDistance.toInt()} km',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primaryPurple,
                      inactiveTrackColor: AppTheme.primaryPurple.withOpacity(
                        0.2,
                      ),
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
            const SizedBox(height: 24),

            // Show me to others switch
            Container(
              padding: const EdgeInsets.all(20),
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
                    fontSize: 14,
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
          ],
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
            options.map((option) {
              final isSelected = selectedOption == option;
              return InkWell(
                onTap: () => onSelected(option),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.4,
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
                        fontSize: 15,
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
}
