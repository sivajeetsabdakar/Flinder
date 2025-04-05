class InterestCategory {
  final String name;
  final String icon;
  final List<InterestOption> options;

  const InterestCategory({
    required this.name,
    required this.icon,
    required this.options,
  });
}

class InterestOption {
  final String name;
  final String emoji;
  bool selected;

  InterestOption({
    required this.name,
    required this.emoji,
    this.selected = false,
  });
}

class InterestsData {
  static final List<InterestCategory> categories = [
    // Food and Drink
    InterestCategory(
      name: 'Food and Drink',
      icon: '🍽️',
      options: [
        InterestOption(name: 'Coffee', emoji: '☕'),
        InterestOption(name: 'BBQ', emoji: '🍖'),
        InterestOption(name: 'Beer', emoji: '🍺'),
        InterestOption(name: 'Biryani', emoji: '🍛'),
        InterestOption(name: 'Boba tea', emoji: '🧋'),
        InterestOption(name: 'Burgers', emoji: '🍔'),
        InterestOption(name: 'Pizza', emoji: '🍕'),
        InterestOption(name: 'Sushi', emoji: '🍣'),
      ],
    ),

    // Sports
    InterestCategory(
      name: 'Sports',
      icon: '🏃',
      options: [
        InterestOption(name: 'Badminton', emoji: '🏸'),
        InterestOption(name: 'Basketball', emoji: '🏀'),
        InterestOption(name: 'Cycling', emoji: '🚴'),
        InterestOption(name: 'Football', emoji: '🏈'),
        InterestOption(name: 'Gym', emoji: '🏋️'),
        InterestOption(name: 'Running', emoji: '🏃'),
        InterestOption(name: 'Soccer', emoji: '⚽'),
        InterestOption(name: 'Swimming', emoji: '🏊'),
      ],
    ),

    // Creativity
    InterestCategory(
      name: 'Creativity',
      icon: '🎨',
      options: [
        InterestOption(name: 'Art', emoji: '🎨'),
        InterestOption(name: 'Crafts', emoji: '🧶'),
        InterestOption(name: 'Dancing', emoji: '💃'),
        InterestOption(name: 'Design', emoji: '✏️'),
        InterestOption(name: 'Photography', emoji: '📷'),
        InterestOption(name: 'Music', emoji: '🎵'),
        InterestOption(name: 'Singing', emoji: '🎤'),
        InterestOption(name: 'Writing', emoji: '✍️'),
      ],
    ),

    // Going Out
    InterestCategory(
      name: 'Going Out',
      icon: '🎭',
      options: [
        InterestOption(name: 'Bars', emoji: '🍻'),
        InterestOption(name: 'Cafe-hopping', emoji: '☕'),
        InterestOption(name: 'Clubs', emoji: '🕺'),
        InterestOption(name: 'Concerts', emoji: '🎵'),
        InterestOption(name: 'Festivals', emoji: '🎪'),
        InterestOption(name: 'Movies', emoji: '🎬'),
        InterestOption(name: 'Theater', emoji: '🎭'),
      ],
    ),

    // Staying In
    InterestCategory(
      name: 'Staying In',
      icon: '🏠',
      options: [
        InterestOption(name: 'Baking', emoji: '🍰'),
        InterestOption(name: 'Board games', emoji: '🎲'),
        InterestOption(name: 'Cooking', emoji: '👨‍🍳'),
        InterestOption(name: 'Reading', emoji: '📚'),
        InterestOption(name: 'Podcasts', emoji: '🎧'),
        InterestOption(name: 'Movies', emoji: '🎬'),
        InterestOption(name: 'Video games', emoji: '🎮'),
      ],
    ),

    // Music
    InterestCategory(
      name: 'Music',
      icon: '🎵',
      options: [
        InterestOption(name: 'Classical', emoji: '🎻'),
        InterestOption(name: 'EDM', emoji: '🎧'),
        InterestOption(name: 'Hip hop', emoji: '🎤'),
        InterestOption(name: 'Indie', emoji: '🎸'),
        InterestOption(name: 'Jazz', emoji: '🎷'),
        InterestOption(name: 'Pop', emoji: '🎵'),
        InterestOption(name: 'Rock', emoji: '🤘'),
      ],
    ),

    // Traveling
    InterestCategory(
      name: 'Traveling',
      icon: '✈️',
      options: [
        InterestOption(name: 'Camping', emoji: '🏕️'),
        InterestOption(name: 'Backpacking', emoji: '🎒'),
        InterestOption(name: 'Beaches', emoji: '🏖️'),
        InterestOption(name: 'City trips', emoji: '🏙️'),
        InterestOption(name: 'Hiking', emoji: '🥾'),
        InterestOption(name: 'Road trips', emoji: '🚗'),
        InterestOption(name: 'Staycations', emoji: '🏠'),
      ],
    ),

    // Personality
    InterestCategory(
      name: 'Personality',
      icon: '😊',
      options: [
        InterestOption(name: 'Active', emoji: '🏃'),
        InterestOption(name: 'Creative', emoji: '🎨'),
        InterestOption(name: 'Funny', emoji: '😂'),
        InterestOption(name: 'Organized', emoji: '📋'),
        InterestOption(name: 'Outgoing', emoji: '🎉'),
        InterestOption(name: 'Relaxed', emoji: '😌'),
        InterestOption(name: 'Thoughtful', emoji: '🤔'),
      ],
    ),
  ];
}
