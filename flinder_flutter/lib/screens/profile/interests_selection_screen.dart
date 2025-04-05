import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/interests_data.dart';
import '../../services/preferences_service.dart';

class InterestsSelectionScreen extends StatefulWidget {
  final Function(List<String>)? onInterestsSelected;
  final List<String>? initialInterests;
  final bool isOnboarding;
  final int maxSelections;

  const InterestsSelectionScreen({
    Key? key,
    this.onInterestsSelected,
    this.initialInterests,
    this.isOnboarding = true,
    this.maxSelections = 5,
  }) : super(key: key);

  @override
  _InterestsSelectionScreenState createState() =>
      _InterestsSelectionScreenState();
}

class _InterestsSelectionScreenState extends State<InterestsSelectionScreen> {
  List<InterestCategory> _categories = [];
  int _currentCategoryIndex = 0;
  int _selectedCount = 0;
  bool _isSaving = false;
  Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _initializeCategories();
    _loadExistingInterests();
  }

  void _initializeCategories() {
    // Create a deep copy of the categories to avoid modifying the original data
    _categories = [];
    for (var category in InterestsData.categories) {
      // Take the existing options (already limited to 7-8 in the model)
      List<InterestOption> options = [];
      for (var option in category.options) {
        bool selected = false;
        if (widget.initialInterests != null) {
          selected = widget.initialInterests!.contains(option.name);
        }
        options.add(
          InterestOption(
            name: option.name,
            emoji: option.emoji,
            selected: selected,
          ),
        );
      }

      _categories.add(
        InterestCategory(
          name: category.name,
          icon: category.icon,
          options: options,
        ),
      );

      // Initialize all categories as collapsed except the first one
      _expandedCategories[category.name] = (_categories.length == 1);
    }

    // Count initially selected interests
    _countSelectedInterests();
  }

  Future<void> _loadExistingInterests() async {
    // Only attempt to load from preferences if not provided in initialInterests
    if (widget.initialInterests == null || widget.initialInterests!.isEmpty) {
      print(
        'InterestsSelectionScreen - Loading existing interests from preferences',
      );
      final prefs = await PreferencesService.getUserPreferences();
      if (prefs != null &&
          prefs.interests != null &&
          prefs.interests!.isNotEmpty) {
        // Get selected interests from preferences and update selection state
        final selectedInterests = prefs.interests!.keys.toList();
        print(
          'InterestsSelectionScreen - Found ${selectedInterests.length} saved interests',
        );

        if (selectedInterests.isNotEmpty) {
          setState(() {
            for (var category in _categories) {
              for (var option in category.options) {
                option.selected = selectedInterests.contains(option.name);
              }
            }
            _countSelectedInterests();
          });
        }
      }
    }
  }

  void _countSelectedInterests() {
    _selectedCount = 0;
    for (var category in _categories) {
      for (var option in category.options) {
        if (option.selected) {
          _selectedCount++;
        }
      }
    }
  }

  void _toggleInterest(InterestOption option) {
    setState(() {
      if (option.selected) {
        option.selected = false;
        _selectedCount--;
      } else {
        option.selected = true;
        _selectedCount++;
      }
    });
  }

  Future<void> _saveInterests() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Collect all selected interests
      List<String> selectedInterests = [];
      for (var category in _categories) {
        for (var option in category.options) {
          if (option.selected) {
            selectedInterests.add(option.name);
          }
        }
      }

      // Call the callback if provided
      if (widget.onInterestsSelected != null) {
        widget.onInterestsSelected!(selectedInterests);
      }

      print('InterestsSelectionScreen - Saving interests: $selectedInterests');

      // Save to preferences service
      final success = await PreferencesService.updateInterests(
        selectedInterests,
      );

      if (mounted) {
        if (success) {
          if (widget.isOnboarding) {
            // Navigate to the next onboarding step or home
            Navigator.of(context).pop(selectedInterests);
          } else {
            // Show success message and pop
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Interests saved successfully'),
                backgroundColor: AppTheme.primaryPurple,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pop(selectedInterests);
          }
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save interests. Please try again.'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving interests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _toggleCategoryExpansion(String categoryName) {
    setState(() {
      _expandedCategories[categoryName] =
          !(_expandedCategories[categoryName] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkerPurple,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Your Interests',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.darkerPurple, AppTheme.darkBackground],
          ),
        ),
        child: Column(
          children: [
            // Selection counter
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.darkGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedCount > 0
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color:
                        _selectedCount > 0
                            ? AppTheme.lightPurple
                            : Colors.white70,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedCount > 0
                          ? 'You\'ve selected $_selectedCount interest${_selectedCount == 1 ? '' : 's'}'
                          : 'Select interests to match with like-minded flatmates',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Category list with expandable sections
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isExpanded =
                      _expandedCategories[category.name] ?? false;

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    color: AppTheme.darkGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppTheme.primaryPurple.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category header
                        InkWell(
                          onTap: () => _toggleCategoryExpansion(category.name),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Text(
                                  category.icon,
                                  style: TextStyle(fontSize: 24),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryPurple.withOpacity(
                                      0.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: AppTheme.lightPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Interest options grid
                        if (isExpanded)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 2.8,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: category.options.length,
                              itemBuilder: (context, optionIndex) {
                                final option = category.options[optionIndex];
                                return _buildInterestItem(option);
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (!widget.isOnboarding)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppTheme.lightPurple),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.lightPurple),
                    ),
                  ),
                ),
              if (!widget.isOnboarding) SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveInterests,
                  child:
                      _isSaving
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterestItem(InterestOption option) {
    final isSelected = option.selected;

    return InkWell(
      onTap: () => _toggleInterest(option),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppTheme.primaryPurple.withOpacity(0.7)
                  : AppTheme.darkBackground.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
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
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Text(option.emoji, style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                option.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
