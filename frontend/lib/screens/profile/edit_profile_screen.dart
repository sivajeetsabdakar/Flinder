import 'package:flutter/material.dart';
import '../../models/profile_model.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bar_with_logout.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/api_constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _bioController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _user;
  ProfileModel? _profile;
  String? _errorMessage;

  // Method to handle interests
  List<String> _selectedInterests = ['Reading', 'Hiking', 'Cooking'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user and profile data
      final user = await AuthService.getCurrentUser();
      final profile = await ProfileService.getCurrentProfile();

      if (mounted) {
        setState(() {
          _user = user;
          _profile = profile;

          // Initialize text controller with existing bio if available
          if (profile != null) {
            _bioController.text = profile.bio;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // If we don't have a profile yet, create a new one with hardcoded values
      if (_profile == null) {
        final userId = _user!.id;

        // Create a new profile with hardcoded data and the bio from text field
        _profile = ProfileModel(
          userId: userId,
          bio: _bioController.text,
          interests: _selectedInterests,
          profilePictures: [
            ProfilePicture(
              id: '1',
              url: 'https://randomuser.me/api/portraits/men/1.jpg',
              isPrimary: true,
              uploadedAt: DateTime.now(),
            ),
          ],
          location: Location(city: 'New York', neighborhood: 'Manhattan'),
          budget: Budget(min: 1000, max: 2000, currency: 'USD'),
          roomPreference: 'private',
          genderPreference: 'any_gender',
          moveInDate: 'flexible',
          leaseDuration: 'long_term',
          lifestyle: Lifestyle(
            schedule: 'flexible',
            noiseLevel: 'moderate',
            cookingFrequency: 'daily',
            diet: 'no_restrictions',
            smoking: 'no',
            drinking: 'occasionally',
            pets: 'comfortable_with_pets',
            cleaningHabits: 'average',
            guestPolicy: 'occasional_guests',
          ),
          languages: ['English'],
        );
      } else {
        // Update the bio in the existing profile
        _profile = ProfileModel(
          userId: _profile!.userId,
          bio: _bioController.text,
          generatedDescription: _profile!.generatedDescription,
          interests: _selectedInterests,
          profilePictures: _profile!.profilePictures,
          location: _profile!.location,
          budget: _profile!.budget,
          roomPreference: _profile!.roomPreference,
          genderPreference: _profile!.genderPreference,
          moveInDate: _profile!.moveInDate,
          leaseDuration: _profile!.leaseDuration,
          lifestyle: _profile!.lifestyle,
          languages: _profile!.languages,
        );
      }

      // Use the ProfileService to update the profile using the /me endpoint
      final token = await AuthService.getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.profileMeEndpoint}',
      );
      log('API Call: PUT ${url.toString()}');
      log('Request Body: ${jsonEncode(_profile!.toJson())}');

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode(_profile!.toJson()),
      );

      log('Response Status: ${response.statusCode}');
      log('Response Body: ${response.body}');

      final success = response.statusCode == 200;

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        } else {
          setState(() {
            _errorMessage = 'Failed to update profile: ${response.body}';
            _isSaving = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error updating profile: $e';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithLogout(title: 'Edit Profile'),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Bio Section
          const Text(
            'About You',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell potential flatmates about yourself, your lifestyle, and what you\'re looking for in a living situation.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bioController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe yourself...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 24),

          // Interests Section
          _buildInterestsSection(),
          const SizedBox(height: 24),

          // Other profile sections would go here
          // For now, we're just showing a message that these fields are hardcoded
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Other Profile Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'For demonstration purposes, other profile fields like location, budget, and preferences will be set to default values.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          Center(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child:
                  _isSaving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'Save Profile',
                        style: TextStyle(fontSize: 16),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interests',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select interests that describe you (up to 5)',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInterestChip('Reading'),
            _buildInterestChip('Gaming'),
            _buildInterestChip('Movies'),
            _buildInterestChip('Music'),
            _buildInterestChip('Cooking'),
            _buildInterestChip('Travel'),
            _buildInterestChip('Hiking'),
            _buildInterestChip('Fitness'),
            _buildInterestChip('Art'),
            _buildInterestChip('Technology'),
          ],
        ),
      ],
    );
  }

  Widget _buildInterestChip(String interest) {
    final isSelected = _selectedInterests.contains(interest);

    return FilterChip(
      label: Text(interest),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            if (_selectedInterests.length < 5) {
              _selectedInterests.add(interest);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You can select up to 5 interests'),
                ),
              );
            }
          } else {
            _selectedInterests.removeWhere((item) => item == interest);
          }
        });
      },
      selectedColor: AppTheme.primaryPurple.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryPurple,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryPurple : Colors.black87,
      ),
    );
  }
}
