import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_theme.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({Key? key}) : super(key: key);

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _pageController = PageController();
  final _cityController = TextEditingController();
  final _ageController = TextEditingController(text: '24');
  final _bioController = TextEditingController();

  int _step = 0;
  bool _isSaving = false;

  String _roomType = 'Private';
  String _budgetRange = '\$500-\$1000';
  String _moveInTimeline = '1-2 months';
  String _schedule = 'Flexible';
  String _noiseLevel = 'Moderate';
  String _cleaningHabit = 'Average';
  String _cookingFrequency = 'Sometimes';
  String _guestPolicy = 'Planned guests';
  String _petPreference = 'Pet friendly';
  String _sleepStyle = 'Balanced sleeper';
  String _socialBattery = 'Balanced';
  String _conflictStyle = 'Talk it out';
  RangeValues _ageRange = const RangeValues(18, 35);
  double _maxDistance = 15;
  bool _showMeToOthers = true;

  final Set<String> _homeVibes = {'Calm', 'Respectful'};
  final Set<String> _dealBreakers = <String>{};
  final Set<String> _interests = {'Movies', 'Food'};

  static const _titles = [
    'Home basics',
    'Daily rhythm',
    'House energy',
    'People fit',
    'Discovery',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
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
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      await AuthService.logout();
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      if (mounted) {
        AppRouter.navigateToLogin(context);
      }
    }
  }

  bool _validateStep() {
    if (_step == 0) {
      final age = int.tryParse(_ageController.text.trim());
      if (_cityController.text.trim().isEmpty || age == null || age < 18) {
        _showSnack('Add your city and a valid age to continue.');
        return false;
      }
    }

    if (_step == 2 && _homeVibes.length < 2) {
      _showSnack('Pick at least two home vibes.');
      return false;
    }

    if (_step == 3 && _interests.length < 3) {
      _showSnack('Pick at least three interests.');
      return false;
    }

    return true;
  }

  void _next() {
    if (!_validateStep()) return;
    if (_step == _titles.length - 1) {
      _completeProfile();
      return;
    }

    setState(() => _step += 1);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _completeProfile() async {
    setState(() => _isSaving = true);

    final success = await UserProfileService.savePreferences(
      city: _cityController.text.trim(),
      roomType: _roomType,
      budgetRange: _budgetRange,
      schedule: _schedule,
      noiseLevel: _noiseLevel,
      cleaningHabits: _cleaningHabit,
      age: int.parse(_ageController.text.trim()),
      ageRange: _ageRange,
      maxDistance: _maxDistance,
      showMeToOthers: _showMeToOthers,
      interests: _interests.toList(),
      homeVibes: _homeVibes.toList(),
      dealBreakers: _dealBreakers.toList(),
      cookingFrequency: _cookingFrequency,
      guestPolicy: _guestPolicy,
      petPreference: _petPreference,
      sleepStyle: _sleepStyle,
      socialBattery: _socialBattery,
      conflictStyle: _conflictStyle,
      moveInTimeline: _moveInTimeline,
      bio: _bioController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      AppRouter.navigateToHome(context);
    } else {
      _showSnack('Could not save your profile. Please try again.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.primaryPurple),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading:
            _step == 0
                ? IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout),
                  onPressed: _handleLogout,
                )
                : IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _back,
                ),
        title: Text(_titles[_step], style: AppTheme.subheadingStyle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _progress(),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _homeBasicsStep(),
                  _dailyRhythmStep(),
                  _houseEnergyStep(),
                  _peopleFitStep(),
                  _discoveryStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _back,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _next,
                      child:
                          _isSaving
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                _step == _titles.length - 1
                                    ? 'Start matching'
                                    : 'Continue',
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress() {
    return Row(
      children: List.generate(_titles.length, (index) {
        final active = index <= _step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 5,
            margin: EdgeInsets.only(right: index == _titles.length - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? AppTheme.accentPink : AppTheme.mediumGrey,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }

  Widget _stepShell({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        Text(title, style: AppTheme.headingStyle.copyWith(fontSize: 26)),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.lightGrey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 22),
        ...children,
      ],
    );
  }

  Widget _homeBasicsStep() {
    return _stepShell(
      title: 'Where should we place you?',
      subtitle:
          'These answers set the hard filters before smart matching kicks in.',
      children: [
        _input(
          controller: _cityController,
          label: 'City',
          hint: 'Mumbai, Pune, Bengaluru...',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 14),
        _input(
          controller: _ageController,
          label: 'Age',
          hint: '24',
          icon: Icons.cake_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _singleChoice(
          label: 'Room type',
          value: _roomType,
          options: const ['Private', 'Shared', 'Studio', 'Any'],
          onChanged: (value) => setState(() => _roomType = value),
        ),
        const SizedBox(height: 20),
        _singleChoice(
          label: 'Budget',
          value: _budgetRange,
          options: const [
            'Under \$500',
            '\$500-\$1000',
            '\$1000-\$1500',
            '\$1500+',
          ],
          onChanged: (value) => setState(() => _budgetRange = value),
        ),
        const SizedBox(height: 20),
        _singleChoice(
          label: 'Move-in timeline',
          value: _moveInTimeline,
          options: const ['This month', '1-2 months', '3+ months'],
          onChanged: (value) => setState(() => _moveInTimeline = value),
        ),
      ],
    );
  }

  Widget _dailyRhythmStep() {
    return _stepShell(
      title: 'What does a normal day look like?',
      subtitle:
          'Quick taps and sliders help us compare routines without making you write an essay.',
      children: [
        _singleChoice(
          label: 'Schedule',
          value: _schedule,
          options: const ['Early Riser', 'Night Owl', 'Flexible'],
          onChanged: (value) => setState(() => _schedule = value),
        ),
        const SizedBox(height: 20),
        _sliderCard(
          label: 'Noise comfort',
          left: 'Silent',
          right: 'Lively',
          divisions: 2,
          value:
              switch (_noiseLevel) {
                'Silent' => 0,
                'Loud' => 2,
                _ => 1,
              }.toDouble(),
          onChanged:
              (value) => setState(() {
                _noiseLevel =
                    value.round() == 0
                        ? 'Silent'
                        : value.round() == 2
                        ? 'Loud'
                        : 'Moderate';
              }),
        ),
        const SizedBox(height: 20),
        _thisOrThat(
          label: 'Cleaning style',
          value: _cleaningHabit,
          options: const ['Very Clean', 'Average', 'Messy'],
          onChanged: (value) => setState(() => _cleaningHabit = value),
        ),
        const SizedBox(height: 20),
        _singleChoice(
          label: 'Cooking frequency',
          value: _cookingFrequency,
          options: const ['Most days', 'Sometimes', 'Rarely'],
          onChanged: (value) => setState(() => _cookingFrequency = value),
        ),
      ],
    );
  }

  Widget _houseEnergyStep() {
    return _stepShell(
      title: 'Pick the home energy',
      subtitle:
          'Choose a few vibes and boundaries. This feeds semantic matching, not just checkbox matching.',
      children: [
        _multiChoice(
          label: 'Home vibes',
          options: const [
            'Calm',
            'Social',
            'Respectful',
            'Study focused',
            'Fitness friendly',
            'Creative',
            'Foodie',
            'Minimal',
            'Festive',
          ],
          selected: _homeVibes,
          min: 2,
          max: 5,
        ),
        const SizedBox(height: 20),
        _multiChoice(
          label: 'Deal breakers',
          options: const [
            'Smoking indoors',
            'Late parties',
            'Messy kitchen',
            'Unplanned guests',
            'Loud calls',
            'Pet allergies',
          ],
          selected: _dealBreakers,
          max: 4,
        ),
        const SizedBox(height: 20),
        _singleChoice(
          label: 'Guests',
          value: _guestPolicy,
          options: const ['Quiet home', 'Planned guests', 'Open house'],
          onChanged: (value) => setState(() => _guestPolicy = value),
        ),
        const SizedBox(height: 20),
        _singleChoice(
          label: 'Pets',
          value: _petPreference,
          options: const ['No pets', 'Pet friendly', 'Have a pet'],
          onChanged: (value) => setState(() => _petPreference = value),
        ),
      ],
    );
  }

  Widget _peopleFitStep() {
    return _stepShell(
      title: 'Now the human part',
      subtitle:
          'These softer signals help the recommender learn compatibility beyond exact interests.',
      children: [
        _thisOrThat(
          label: 'Sleep style',
          value: _sleepStyle,
          options: const [
            'Light sleeper',
            'Balanced sleeper',
            'Can sleep through anything',
          ],
          onChanged: (value) => setState(() => _sleepStyle = value),
        ),
        const SizedBox(height: 20),
        _singleChoice(
          label: 'Social battery',
          value: _socialBattery,
          options: const ['Recharge alone', 'Balanced', 'Always social'],
          onChanged: (value) => setState(() => _socialBattery = value),
        ),
        const SizedBox(height: 20),
        _singleChoice(
          label: 'Conflict style',
          value: _conflictStyle,
          options: const ['Talk it out', 'Need a pause', 'Prefer house rules'],
          onChanged: (value) => setState(() => _conflictStyle = value),
        ),
        const SizedBox(height: 20),
        _multiChoice(
          label: 'Interests',
          options: const [
            'Movies',
            'Music',
            'Gaming',
            'Reading',
            'Fitness',
            'Travel',
            'Startups',
            'Cooking',
            'Football',
            'Anime',
            'Art',
            'Night markets',
          ],
          selected: _interests,
          min: 3,
          max: 7,
        ),
        const SizedBox(height: 20),
        _input(
          controller: _bioController,
          label: 'One-line intro',
          hint: 'I like tidy kitchens, late-night chai, and quiet weekdays.',
          icon: Icons.edit_note,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _discoveryStep() {
    return _stepShell(
      title: 'Tune discovery',
      subtitle:
          'Set who appears in your swipe stack. You can change this anytime.',
      children: [
        _rangeCard(
          label: 'Preferred age range',
          value: _ageRange,
          min: 18,
          max: 60,
          onChanged: (value) => setState(() => _ageRange = value),
        ),
        const SizedBox(height: 20),
        _sliderCard(
          label: 'Distance',
          left: '5 km',
          right: '50 km',
          value: _maxDistance,
          min: 5,
          max: 50,
          divisions: 9,
          display: '${_maxDistance.round()} km',
          onChanged: (value) => setState(() => _maxDistance = value),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _panelDecoration(),
          child: SwitchListTile.adaptive(
            value: _showMeToOthers,
            onChanged: (value) => setState(() => _showMeToOthers = value),
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.accentPink,
            title: const Text('Show me in discovery'),
            subtitle: Text(
              'Turn this off if you want to browse quietly.',
              style: TextStyle(color: AppTheme.lightGrey.withOpacity(0.85)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textInputAction: maxLines == 1 ? TextInputAction.next : null,
          decoration: AppTheme.inputDecoration(
            hintText: hint,
            prefixIcon: icon,
          ),
        ),
      ],
    );
  }

  Widget _singleChoice({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              options.map((option) {
                final selected = option == value;
                return ChoiceChip(
                  label: Text(option),
                  selected: selected,
                  onSelected: (_) => onChanged(option),
                  selectedColor: AppTheme.primaryPurple,
                  backgroundColor: AppTheme.darkGrey,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.lightGrey,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color:
                        selected
                            ? AppTheme.accentPink
                            : AppTheme.mediumGrey.withOpacity(0.4),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _multiChoice({
    required String label,
    required List<String> options,
    required Set<String> selected,
    int min = 0,
    int max = 99,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _label(label)),
            Text(
              min > 0
                  ? '${selected.length}/$min min'
                  : '${selected.length}/$max',
              style: TextStyle(color: AppTheme.lightGrey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              options.map((option) {
                final isSelected = selected.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        if (selected.length < max) selected.add(option);
                      } else {
                        selected.remove(option);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryPurple,
                  checkmarkColor: Colors.white,
                  backgroundColor: AppTheme.darkGrey,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.lightGrey,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color:
                        isSelected
                            ? AppTheme.accentPink
                            : AppTheme.mediumGrey.withOpacity(0.4),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _thisOrThat({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 12),
          Row(
            children:
                options.map((option) {
                  final selected = option == value;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: option == options.last ? 0 : 8,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onChanged(option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 82,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                selected
                                    ? AppTheme.primaryPurple
                                    : AppTheme.darkBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  selected
                                      ? AppTheme.accentPink
                                      : AppTheme.mediumGrey.withOpacity(0.45),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              option,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _sliderCard({
    required String label,
    required String left,
    required String right,
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0,
    double max = 2,
    int? divisions,
    String? display,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label(label)),
              Text(
                display ?? _noiseLevel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppTheme.accentPink,
            inactiveColor: AppTheme.mediumGrey,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(left, style: TextStyle(color: AppTheme.lightGrey)),
              Text(right, style: TextStyle(color: AppTheme.lightGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeCard({
    required String label,
    required RangeValues value,
    required double min,
    required double max,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _label(label)),
              Text(
                '${value.start.round()}-${value.end.round()}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          RangeSlider(
            values: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            activeColor: AppTheme.accentPink,
            inactiveColor: AppTheme.mediumGrey,
            labels: RangeLabels(
              value.start.round().toString(),
              value.end.round().toString(),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _label(String value) {
    return Text(value, style: AppTheme.subheadingStyle.copyWith(fontSize: 15));
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: AppTheme.darkGrey,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.mediumGrey.withOpacity(0.35)),
    );
  }
}
