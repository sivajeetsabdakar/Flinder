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

  // Threshold for how far card needs to be dragged for an action
  final double _threshold = 100;

  @override
  void initState() {
    super.initState();
    _initializeProfiles();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenSize = MediaQuery.of(context).size;
    });
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

    return Container(
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
                scale: 0.9,
                child: Opacity(
                  opacity: 0.6,
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
                  final swipeProgress = min(
                    abs(_position.dx) / _threshold,
                    1.0,
                  );

                  return Transform(
                    transform: rotatedMatrix,
                    child: Stack(
                      children: [
                        _buildCardContent(_currentProfiles[0]),

                        // LIKE overlay (when swiping left)
                        Positioned.fill(
                          child: Opacity(
                            opacity:
                                swipeDirection == SwipeDirection.left
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
                                  angle: -pi / 12,
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

                        // PASS overlay (when swiping right)
                        Positioned.fill(
                          child: Opacity(
                            opacity:
                                swipeDirection == SwipeDirection.right
                                    ? swipeProgress
                                    : 0,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.red, width: 5),
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

          // Instructions text at bottom
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.darkerPurple.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Swipe left to like, right to pass',
                style: TextStyle(
                  color: AppTheme.lightPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _position = Offset.zero;
      _angle = 0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      // Apply slight rotation based on horizontal drag
      _angle = _position.dx / 300;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentProfiles.isEmpty) return;

    final currentProfile = _currentProfiles[0];

    // If the card was dragged beyond threshold, trigger appropriate action
    if (_position.dx > _threshold) {
      // Swiped right = dislike
      widget.onSwipeRight(currentProfile);
      _removeTopCard();
    } else if (_position.dx < -_threshold) {
      // Swiped left = like
      widget.onSwipeLeft(currentProfile);
      _removeTopCard();
    } else {
      // Card was not dragged far enough, return to center
      setState(() {
        _position = Offset.zero;
        _angle = 0;
      });
    }
  }

  void _removeTopCard() {
    setState(() {
      if (_currentProfiles.isNotEmpty) {
        _currentProfiles.removeAt(0);
        _position = Offset.zero;
        _angle = 0;
      }
    });
  }

  Widget _buildCardContent(UserProfile profile) {
    // Debug profile name
    print(
      'Building card for profile: ${profile.name}, ID: ${profile.preferences?['UserID'] ?? 'unknown'}',
    );

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
              child:
                  profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: profile.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryPurple,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => const Center(
                              child: Icon(
                                Icons.person,
                                size: 100,
                                color: Colors.grey,
                              ),
                            ),
                      )
                      : const Center(
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.grey,
                        ),
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
                "ID: ${profile.preferences?['UserID'] ?? 'Unknown'}",
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
