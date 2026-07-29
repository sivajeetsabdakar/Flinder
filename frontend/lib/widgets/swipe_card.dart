import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class SwipeCard extends StatefulWidget {
  final List<UserProfile> profiles;
  final Function(UserProfile) onSwipeLeft;
  final Function(UserProfile) onSwipeRight;

  const SwipeCard({
    Key? key,
    required this.profiles,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  }) : super(key: key);

  @override
  _SwipeCardState createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  Size _screenSize = Size.zero;
  double _angle = 0;
  List<UserProfile> _currentProfiles = [];
  late final AnimationController _animationController;
  Animation<Offset>? _positionAnimation;
  Animation<double>? _angleAnimation;
  bool _isAnimatingOut = false;

  // Threshold for how far card needs to be dragged for an action
  final double _threshold = 120;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
      if (_positionAnimation == null || _angleAnimation == null) return;
      setState(() {
        _position = _positionAnimation!.value;
        _angle = _angleAnimation!.value;
      });
    });
    _initializeProfiles();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenSize = MediaQuery.of(context).size;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profiles != widget.profiles) {
      _initializeProfiles();
    }
  }

  void _initializeProfiles() {
    setState(() {
      _currentProfiles = List.from(widget.profiles);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentProfiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No more profiles to show',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later or try refreshing',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Show back card (next profile) if available
          if (_currentProfiles.length > 1)
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              bottom: 10,
              child: Transform.scale(
                scale: 0.92 + (0.04 * _swipeProgress),
                child: Opacity(
                  opacity: 0.55 + (0.2 * _swipeProgress),
                  child: _buildCardContent(_currentProfiles[1]),
                ),
              ),
            ),

          // Current profile swipeable card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onTap: () => _showProfileDetails(context, _currentProfiles[0]),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate rotation and position based on drag
                  final center = constraints.smallest.center(Offset.zero);
                  final rotatedMatrix =
                      Matrix4.identity()
                        ..translate(center.dx, center.dy)
                        ..rotateZ(_angle)
                        ..translate(-center.dx, -center.dy)
                        ..translate(_position.dx, _position.dy);

                  // Calculate feedback opacity based on position
                  final swipeDirection =
                      _position.dx > 0
                          ? SwipeDirection.right
                          : SwipeDirection.left;
                  final swipeProgress = _swipeProgress;

                  return Transform(
                    transform: rotatedMatrix,
                    child: Stack(
                      children: [
                        _buildCardContent(_currentProfiles[0]),

                        // LIKE overlay (when swiping right)
                        Positioned.fill(
                          child: Opacity(
                            opacity:
                                swipeDirection == SwipeDirection.right
                                    ? swipeProgress
                                    : 0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green,
                                  width: 5,
                                ),
                              ),
                              child: Center(
                                child: Transform.rotate(
                                  angle: pi / 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'LIKE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // PASS overlay (when swiping left)
                        Positioned.fill(
                          child: Opacity(
                            opacity:
                                swipeDirection == SwipeDirection.left
                                    ? swipeProgress
                                    : 0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.red, width: 5),
                              ),
                              child: Center(
                                child: Transform.rotate(
                                  angle: -pi / 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'PASS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          Positioned(bottom: 18, child: _buildActionButtons()),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimatingOut) return;
    _animationController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimatingOut) return;
    setState(() {
      _position += details.delta;
      _angle = (_position.dx / 320).clamp(-0.38, 0.38);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimatingOut) return;
    if (_currentProfiles.isEmpty) return;

    final currentProfile = _currentProfiles[0];
    final velocity = details.velocity.pixelsPerSecond.dx;

    if (_position.dx > _threshold || velocity > 900) {
      _animateCardOut(SwipeDirection.right, currentProfile);
    } else if (_position.dx < -_threshold || velocity < -900) {
      _animateCardOut(SwipeDirection.left, currentProfile);
    } else {
      _animateCardBack();
    }
  }

  double get _swipeProgress => min(abs(_position.dx) / _threshold, 1.0);

  Future<void> _animateCardBack() async {
    _positionAnimation = Tween<Offset>(
      begin: _position,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _angleAnimation = Tween<double>(begin: _angle, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    await _animationController.forward(from: 0);
  }

  Future<void> _animateCardOut(
    SwipeDirection direction,
    UserProfile currentProfile,
  ) async {
    _isAnimatingOut = true;
    final width =
        _screenSize.width == 0
            ? MediaQuery.of(context).size.width
            : _screenSize.width;
    final endX =
        direction == SwipeDirection.right ? width * 1.35 : -width * 1.35;
    final endY = _position.dy + 80;

    _positionAnimation = Tween<Offset>(
      begin: _position,
      end: Offset(endX, endY),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInCubic),
    );
    _angleAnimation = Tween<double>(
      begin: _angle,
      end: direction == SwipeDirection.right ? 0.55 : -0.55,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInCubic),
    );

    await _animationController.forward(from: 0);

    if (direction == SwipeDirection.right) {
      widget.onSwipeRight(currentProfile);
    } else {
      widget.onSwipeLeft(currentProfile);
    }

    setState(() {
      if (_currentProfiles.isNotEmpty) {
        _currentProfiles.removeAt(0);
      }
      _position = Offset.zero;
      _angle = 0;
      _isAnimatingOut = false;
    });
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCircleAction(
          icon: Icons.close,
          color: Colors.redAccent,
          onTap: () {
            if (_currentProfiles.isNotEmpty) {
              _animateCardOut(SwipeDirection.left, _currentProfiles[0]);
            }
          },
        ),
        const SizedBox(width: 26),
        _buildCircleAction(
          icon: Icons.favorite,
          color: Colors.green,
          onTap: () {
            if (_currentProfiles.isNotEmpty) {
              _animateCardOut(SwipeDirection.right, _currentProfiles[0]);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.48),
      shape: const CircleBorder(),
      elevation: 8,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.85), width: 2),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
      ),
    );
  }

  Widget _buildCardContent(UserProfile profile) {
    final imageUrl =
        profile.photoUrl != null && profile.photoUrl!.isNotEmpty
            ? profile.photoUrl!
            : 'https://images.unsplash.com/photo-1494790108377-be9c29b29330';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      color: Colors.black,
      child: Stack(
        children: [
          // Main image placeholder
          Positioned.fill(
            child: Container(
              color: Colors.grey.shade900,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                errorWidget: (context, url, error) {
                  return const Center(
                    child: Icon(Icons.person, size: 100, color: Colors.grey),
                  );
                },
              ),
            ),
          ),

          // Top banner with user ID
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Text(
                "ID: ${profile.id}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),

          // Bottom gradient and info
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.95),
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name with larger font and white color for emphasis
                  Text(
                    profile.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Age and online status row
                  Row(
                    children: [
                      Text(
                        "${profile.age} years",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      if (profile.preferences != null &&
                          profile.preferences!.containsKey('Online') &&
                          profile.preferences!['Online'] == 'Yes')
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Location with icon
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          profile.location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Show room type and budget
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        _buildTagChip(profile.roomType),
                        const SizedBox(width: 8),
                        _buildTagChip(profile.budget ?? 'Flexible'),
                      ],
                    ),
                  ),

                  // Show interests as chips
                  if (profile.interests != null &&
                      profile.interests!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children:
                            profile.interests!
                                .take(3)
                                .map((interest) => _buildInterestChip(interest))
                                .toList(),
                      ),
                    ),

                  // Description if available
                  if (profile.preferences != null &&
                      profile.preferences!.containsKey('Description') &&
                      profile.preferences!['Description'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        profile.preferences!['Description'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Last active info
                  if (profile.preferences != null &&
                      profile.preferences!.containsKey('Last active'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white60,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Last active: ${profile.preferences!['Last active']}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple tag chip for displaying basic info
  Widget _buildTagChip(String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // Interest chip with different styling
  Widget _buildInterestChip(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.lightPurple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.lightPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        interest,
        style: TextStyle(color: AppTheme.lightPurple, fontSize: 12),
      ),
    );
  }

  void _showProfileDetails(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (context, scrollController) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Name and age
                        Text(
                          '${profile.name}, ${profile.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile.location,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Bio
                        if (profile.bio != null && profile.bio!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'About',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                profile.bio!,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),

                        // Interests
                        if (profile.interests != null &&
                            profile.interests!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Interests',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    profile.interests!.map((interest) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryPurple
                                              .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          interest,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),

                        // Preferences
                        if (profile.preferences != null &&
                            profile.preferences!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Preferences',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...profile.preferences!.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${entry.key}:',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        entry.value,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }
}

enum SwipeDirection { left, right }

// Helper function to get absolute value
double abs(double value) => value < 0 ? -value : value;
